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
	let providerAsset
	let providerOrderList

	beforeEach(async () => {
		[deployer, providerAddr, providerAddrBeta] = await ethers.getSigners();
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

		const _providerAsset = await ethers.getContractFactory('CurciferAsset');
		providerAsset = await _providerAsset.connect(providerAddr).deploy(providerAddr.address, providerOrderList.address, deployer.address);
		await providerAsset.deployed();

		await providerAsset.connect(providerAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);

	})

	describe("Test New Asset Creation", async () => {

		it("Pay fee should make order ready ", async () => {

			var _orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 2);
			expect(_orderBookFlag[0].isApproved).to.equal(false);

			await tokenE.connect(deployer).mint(providerAddr.address, 100);

			const _countTokenE = await tokenE.balanceOf(providerAddr.address);
			expect(_countTokenE).to.equal(100);

			await tokenE.connect(providerAddr).approve(providerAsset.address, 100);

			await providerAsset.connect(providerAddr).payFee(0);

			_orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 2);
			expect(_orderBookFlag[0].isApproved).to.equal(true);

		})

		it("Get OrderBook first page should return list of order info", async () => {
			await providerAsset.connect(providerAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);
			
			var _orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 10);
			expect(_orderBookFlag.length).to.equal(2);
		})
	})
})