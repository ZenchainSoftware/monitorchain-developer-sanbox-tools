'use strict';
const Web3js = require('web3');
const {MonitorChain, ERC20} = require('./common/interface');
const tokens = require('./config/tokens');
const tokenAbi = require('./ethereum/build/McnToken');

// Config
const config = require('./common/readConfig')();
const nodeAddress = config.nodeAddress;
const userMnemonic = config.mnemonic;
const addresses = config.addresses;

const gasPrice = config.gasPrice;
const gasLimit = config.gasLimit;

const monitor = new MonitorChain(nodeAddress, addresses.monitorAddress, userMnemonic);

const _to = (promise) => {
    return promise.then(data => {
        return [null, data];
    })
        .catch(err => [err, null]);
};

const getNonce = async(instance) => {
    await instance.init();
    return await instance.w3.eth.getTransactionCount(instance.wallet);
};

const getToken = async(address, mnemonic, abi) => {
    address = address || tokens[0];
    mnemonic = mnemonic || userMnemonic;
    abi = abi || tokenAbi.abi;
    const token = new ERC20(nodeAddress, address, mnemonic, null, abi);
    token.gasPrice = gasPrice;
    await token.init();
    await token.tokenInfo();
    return token;
};

const addTokensToMonitorChain = async (tokens) => {
    console.log("\nAdding tokens to MonitorChain\n" + "-".repeat(60));
    let nonce = await getNonce(monitor);
    const promises = [];
    const supportedTokens = await monitor.getAllSupportedTokens();
    let err, res;
    for (let address of tokens) {
        address = Web3js.utils.toChecksumAddress(address);
        const token = await getToken(address);
        if(supportedTokens.indexOf(address) >= 0) {
            console.log(`Token ${address} (${token.info.name}) is already supported.`);
            continue;
        }
        promises.push(new Promise(async (resolve, reject) => {
            try {
                [err, res] = await _to(monitor.contract.methods.addSupportedToken(address)
                    .send({
                        from: monitor.wallet,
                        gas: gasLimit,
                        gasPrice: gasPrice,
                        nonce: nonce
                    }));
            } catch (e) {
                err = e
            }
            if (err) {
                console.log(`\nAn error has occurred while adding a token ${address} (${token.info.name}) to MonitorChain: ${err}\n`);
            } else {
                console.log(`Successfully added token ${address} (${token.info.name}) to MonitorChain`);
            }
            resolve();
        }));
        nonce++;
    }
    await Promise.all(promises)
        .then(res => console.log("-".repeat(60) + "\n"))
        .catch(err => console.log(`\nAn error has occurred while adding tokens to MonitorChain\n${err}\n`));
};

const removeTokensFromMonitorChain = async (tokens) => {
    console.log("\nRemoving tokens from MonitorChain\n" + "-".repeat(60));
    let nonce = await getNonce(monitor);
    const promises = [];
    const supportedTokens = await monitor.getAllSupportedTokens();
    let err, res;
    for (let address of tokens) {
        address = Web3js.utils.toChecksumAddress(address);
        const token = await getToken(address);
        if(supportedTokens.indexOf(address) < 0) {
            console.log(`Token ${address} (${token.info.name}) is not supported.`);
            continue;
        }
        promises.push(new Promise(async (resolve, reject) => {
            try {
                [err, res] = await _to(monitor.contract.methods.removeSupportedToken(address)
                    .send({
                        from: monitor.wallet,
                        gas: gasLimit,
                        gasPrice: gasPrice,
                        nonce: nonce
                    }));
            } catch (e) {
                err = e
            }
            if (err) {
                console.log(`\nAn error has occurred while removing a token ${address} (${token.info.name}) from MonitorChain: ${err}\n`);
            } else {
                console.log(`Successfully removed token ${address} (${token.info.name}) from MonitorChain`);
            }
            resolve();
        }));
        nonce++;
    }
    await Promise.all(promises)
        .then(res => console.log("-".repeat(60) + "\n"))
        .catch(err => console.log(`\nAn error has occurred while while removing tokens from MonitorChain\n${err}\n`));
};


const reset = async() => {
    await removeTokensFromMonitorChain(tokens);
    console.log('RESET DONE')
};

const init = async () => {
    await addTokensToMonitorChain(tokens);

    console.log('INIT DONE')
};

reset().then(init).then(process.exit);
