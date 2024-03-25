// require("@nomiclabs/hardhat-truffle5");

module.exports = {
  networks: {
    hardhat: {},
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
};
