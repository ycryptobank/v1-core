const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test TradeList Contract", () => {
    let deployer
	let providerAddr
	let orderListContractAddr
	let tokenA
	let tokenB
	let tokenC
	let tokenD
	let tokenE
	let tradeList

	beforeEach(async () => {
		[deployer, providerAddr, orderListContractAddr] = await ethers.getSigners();
		const _providerToken = await ethers.getContractFactory('ERC20PresetMinterPauser');
		tokenA = await _providerToken.deploy("TokenA", "TA");
		tokenB = await _providerToken.deploy("TokenB", "TB");
		tokenC = await _providerToken.deploy("TokenC", "TC");
		tokenD = await _providerToken.deploy("TokenD", "TD");
		tokenE = await _providerToken.deploy("TokenE", "TE");
		await tokenA.deployed();
		await tokenB.deployed();
		await tokenC.deployed();
		await tokenD.deployed();
		await tokenE.deployed();

		const _ycbTradeList = await ethers.getContractFactory('YCBTradeList');
		tradeList = await _ycbTradeList.connect(providerAddr).deploy();
		await tradeList.deployed();

	})
})