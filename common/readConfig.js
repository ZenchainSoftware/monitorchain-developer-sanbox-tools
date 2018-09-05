'use strict';
const config = require('config');
const Web3 = require('web3');

const toWei = (amount, unit) => {
    return Web3.utils.toWei(amount.toString(), unit);
};

const getNode = (proto, chainName) => {
    const defaultProtocol = config.get('defaults.protocol');
    const defaultNetwork = config.get('defaults.network');
    let protocol = proto || defaultProtocol;
    let network = chainName || defaultNetwork;
    let nodeAddress;

    if (config.has(`networks.${network}.${defaultProtocol}`)) {
        nodeAddress = config.get(`networks.${network}.${defaultProtocol}`);
    } else {
        //fallback to http address in order to reduce the config size
        nodeAddress = config.get(`networks.${network}.http`);
    }

    if (config.has(`networks.${network}.${protocol}`)) {
        nodeAddress = config.get(`networks.${network}.${protocol}`)
    }

    return nodeAddress;
};

const configData = (proto, chainName) => {
    const mnemonic = config.get('truffle.mnemonic');

    const defaultNet = config.get('defaults.network');
    const nodeAddress = getNode(proto, defaultNet);
    const addresses = config.get(`addresses`);
    const gasPrice = config.get('truffle.gasPrice');
    const gasLimit = config.get('truffle.gasLimit');


    return {
        nodeAddress: nodeAddress,
        mnemonic: mnemonic,
        addresses: addresses,
        gasPrice: toWei(gasPrice, 'gwei'),
        gasLimit: gasLimit
    };
};

module.exports = configData;
