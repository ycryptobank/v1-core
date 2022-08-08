const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Curcifer Order", () => {
	let deployer
	let providerAddr
	let providerAddrBeta
	let tokenA
	let tokenB
	let tokenC
	let tokenD
	let tokenE
	let tokenFee
	let providerOrderList

	beforeEach(async () => {
		[deployer, providerAddr, providerAddrBeta] = await ethers.getSigners();
		const _providerToken = await ethers.getContractFactory('ERC20PresetMinterPauser');
		tokenA = await _providerToken.deploy("TokenA", "TA");
		tokenB = await _providerToken.deploy("TokenB", "TB");
		tokenC = await _providerToken.deploy("TokenC", "TC");
		tokenD = await _providerToken.deploy("TokenD", "TD");
		tokenE = await _providerToken.deploy("TokenE", "TE");
		tokenFee = await _providerToken.deploy("TokenFee", "TF");
		await tokenA.deployed();
		await tokenB.deployed();
		await tokenC.deployed();
		await tokenD.deployed();
		await tokenE.deployed();
		await tokenFee.deployed();

		const _providerOrderList = await ethers.getContractFactory('CurciferOrderList');
		providerOrderList = await _providerOrderList.connect(deployer).deploy();
		await providerOrderList.deployed();
		
		await providerOrderList.connect(deployer).addFeeList(tokenFee.address, 1);
	})

	describe("Test New Order Creation", async () => {
		it("create new order with new account will create new orderlist", async () => {
			const _countOrderListBefore = await providerOrderList.getCountProviderList();
			await providerOrderList.connect(providerAddr).createNewOrder(tokenA.address, tokenB.address, 10, 10, 100, 100, 0, 0, 0);
			const _countOrderListAfter = await providerOrderList.getCountProviderList();
			expect(_countOrderListAfter).to.equal(1);
			expect(_countOrderListBefore).to.equal(0);
			await providerOrderList.connect(providerAddrBeta).createNewOrder(tokenC.address, tokenA.address, 100, 100, 10 , 10, 0, 0, 0);
			const _countOrderListAfterMultiplied = await providerOrderList.getCountProviderList();
			expect(_countOrderListAfterMultiplied).to.equal(2);
		})

		it("create multiple order same account will not create new orderlist", async() => {
			await providerOrderList.connect(providerAddr).createNewOrder(tokenA.address, tokenB.address, 10, 10, 100, 100, 0, 0, 0);
			await providerOrderList.connect(providerAddr).createNewOrder(tokenC.address, tokenA.address, 100, 100, 10 , 10, 0, 0, 0);
			const _countOrderList = await providerOrderList.getCountProviderList();
			expect(_countOrderList).to.equal(1);
			await providerOrderList.connect(providerAddr).createNewOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, 0);
			await providerOrderList.connect(providerAddr).createNewOrder(tokenD.address, tokenE.address, 100, 100, 10 , 10, 0, 0, 0);
			expect(_countOrderList).to.equal(1);
		})
	})
})