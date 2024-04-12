require('@nomiclabs/hardhat-truffle5');
require('@nomicfoundation/hardhat-chai-matchers');

module.exports = {
  networks: {
    hardhat: {},
  },
  solidity: {
    version: '0.8.19',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
};
