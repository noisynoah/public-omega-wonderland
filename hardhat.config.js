require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();


module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        hardhat: {},
        ropsten: {
            accounts: [""],
            chainId: 3,
            url: "https://ropsten.infura.io/v3/11359f968f3a48318bbb4f19ccc1c42d",
            gas: 4100000,
            gasPrice: 50000000000
        },
        "bsc-testnet": {
            accounts: [""],
            // accounts: [process.env.TESTNET_PRIVATE_KEY],
            chainId: 97,
            url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
            gas: 2100000,
            gasPrice: 10000000000
        },
        mainnet: {
            accounts: [""],
            chainId: 56,
            url: "https://bsc-dataseed.binance.org/",
            gas: 2100000,
            gasPrice: 10000000000
        },
        // // bsc: {
        // //   accounts: [process.env.MAINNET_PRIVATE_KEY],
        // //   chainId: 56,
        // //   url: "https://bsc-dataseed.binance.org/",
        // // },
        // mainnet: {
        //     accounts: [process.env.MAINNET_PRIVATE_KEY],
        //     chainId: 56,
        //     url: "https://bsc-dataseed.binance.org/",
        // },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
    },
};