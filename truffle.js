require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
	networks: {
		development: {
			provider: function () {
				return new HDWalletProvider(
					process.env.SECRET_PHRASE,
					'http://127.0.0.1:8545/',
					0,
					50
				);
			},
			gas: 5000000,
			gasPrice: 1000000000,
			network_id: '*',
		},
		rinkeby: {
			provider: () =>
				new HDWalletProvider(
					process.env.SECRET_PHRASE,
					process.env.NETWORK_ENDPOINTS
				),
			gas: 5000000,
			gasPrice: 1000000000,
			network_id: '*',
		},
	},
	compilers: {
		solc: {
			version: '^0.8.0',
		},
	},
};
