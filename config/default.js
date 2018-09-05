module.exports = {
    defaults: {
        protocol: "http", // <--- set protocol type - http, ws, wss, or ipc
        network: "rinkeby"
    },
    truffle: {
        mnemonic: "", // <--- paste a mnemonic
        gasLimit: 6000000,
        gasPrice: '6', // gwei
    },
    addresses: {
        monitorAddress: ""
    },

    networks: {
        rinkeby: {
            http: "http://localhost:8545", // http link is required!
            // optional parameters
            wss: "wss://localhost:8543",
            ws: "ws://localhost:8543",
            ipc: "ipc://path/to/geth/geth.ipc"
        }
    }
};
