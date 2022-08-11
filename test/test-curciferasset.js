const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Curcifer Order", () => {
	let deployer
	let providerAddr
	let orderListContractAddr
	let tokenA
	let tokenB
	let tokenC
	let tokenD
	let tokenE
	let providerAsset

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

		const _providerAsset = await ethers.getContractFactory('CurciferAsset');
		providerAsset = await _providerAsset.connect(providerAddr).deploy(providerAddr.address, orderListContractAddr.address, deployer.address);
		await providerAsset.deployed();

		await providerAsset.connect(orderListContractAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);

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
			await providerAsset.connect(orderListContractAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);

			_orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 2);
			expect(_orderBookFlag[0].isApproved).to.equal(true);
			expect(_orderBookFlag[1].isApproved).to.equal(false);
		})

		it('Pay Fee should emit and event', async () => {
			await providerAsset.connect(orderListContractAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);
			
			_orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 2);
			expect(_orderBookFlag[0].isApproved).to.equal(false);
			expect(_orderBookFlag[1].isApproved).to.equal(false);

			await tokenE.connect(deployer).mint(providerAddr.address, 100);
			await tokenE.connect(providerAddr).approve(providerAsset.address, 100);

			await expect(providerAsset.connect(providerAddr).payFee(0)).to.emit(providerAsset, "PaidFee");
		})

		it("Get OrderBook first page should return list of order info", async () => {
			await providerAsset.connect(orderListContractAddr).addOrder(tokenB.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);
			
			var _orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 10);
			expect(_orderBookFlag.length).to.equal(2);

			await providerAsset.connect(orderListContractAddr).addOrder(tokenA.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);
			_orderBookFlag = await providerAsset.connect(providerAddr).getOrderBook(1, 10);
			expect(_orderBookFlag.length).to.equal(3);
		})

		it("Deposit Provider will deposit correctly", async () => {
			// TO DO: parameter deposit will change in future
			await expect(providerAsset.connect(providerAddr).deposit(0)).to.be.revertedWith('NotYetPaidFee');

			await providerAsset.connect(orderListContractAddr).addOrder(tokenD.address, tokenC.address, 100, 100, 10 , 10, 0, 0, tokenE.address, 1);
		})
	})
})