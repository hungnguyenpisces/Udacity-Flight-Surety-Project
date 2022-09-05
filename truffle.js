const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic =
	'candy maple cake sugar pudding cream honey rich smooth crumble sweet treat';

module.exports = {
	networks: {
		development: {
			provider: function () {
				return new HDWalletProvider(mnemonic, 'http://127.0.0.1:8545/', 0, 50);
			},
			network_id: '*',
			gas: 9999999,
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
