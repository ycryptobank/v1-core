const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Curcifer Order", () => {
	let deployer
	let providerAddr
	let customerAddr
	let tokenA
	let tokenB
	let tokenC
	let tokenD
	let tokenE
	let providerOrderList

	beforeEach(async () => {
		[deployer, providerAddr, customerAddr] = await ethers.getSigners();
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

		const _providerOrderList = await ethers.getContractFactory('CurciferOrderList');
		providerOrderList = await _providerOrderList.connect(deployer).deploy();
		await providerOrderList.deployed();
	})

	describe("Test New Order Creation", async () => {
		it("create new order", async () => {
			const _countOrderListBefore = await providerOrderList.assetCreatedCounter();
			await providerOrderList.connect(providerAddr).createNewOrder(tokenA.address, tokenB.address, 10, 10, 100, 100);
			const _countOrderListAfter = await providerOrderList.assetCreatedCounter();
			expect(_countOrderListAfter).to.equal(1);
			expect(_countOrderListBefore).to.equal(0);
		})
	})
})