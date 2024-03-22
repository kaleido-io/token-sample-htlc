module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545, // default for Ganache
      network_id: '1337',
    },
  },
  compilers: {
    solc: {
      version: '0.8.19',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200, // Optimize for how many times you intend to run the code
        },
        viaIR: true,
      },
    },
  },
  solidityLog: {
    displayPrefix: ' :', // defaults to ""
    preventConsoleLogMigration: true, // defaults to false
  },
};
