const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("CurciferDex Tests", () => {
let deployer
let accountProvider
let accountTarget
let testTheTokenProvider
let testTheTokenTarget
let testTheTokenFee
let mockPool

	beforeEach(async () => {

		[deployer, accountProvider, accountTarget] = await ethers.getSigners();

		const TestTheTokenProvider = await ethers.getContractFactory('ERC20PresetMinterPauser');
		testTheTokenProvider = await TestTheTokenProvider.deploy("TestTheTokenProvider", "TTP");
		await testTheTokenProvider.deployed();

		const TestTheTokenTarget = await ethers.getContractFactory('ERC20PresetMinterPauser');
		testTheTokenTarget = await TestTheTokenTarget.deploy("TestTheTokenTarget", "TTT");
		await testTheTokenTarget.deployed();

		const TestTheTokenFee = await ethers.getContractFactory('ERC20PresetMinterPauser');
		testTheTokenFee = await TestTheTokenFee.deploy("TestTheTokenFee", 'TTF');
		await testTheTokenFee.deployed();

		const MockPool = await ethers.getContractFactory('MockPool');
		mockPool = await MockPool.deploy(deployer.address);
		await mockPool.deployed();
	});

	describe('Test Valid Transaction for personal Dex', async () => {
		it('check account token distribution', async () => {

			await testTheTokenProvider.mint(mockPool.address, 100000);
			await testTheTokenTarget.mint(mockPool.address, 200000);

			const poolBalanceProvider = await testTheTokenProvider.balanceOf(mockPool.address);
			const poolBalanceTarget = await testTheTokenTarget.balanceOf(mockPool.address);

			expect(poolBalanceProvider).to.equal(100000);
			expect(poolBalanceTarget).to.equal(200000);

			await mockPool.connect(accountProvider).giveErc20(testTheTokenProvider.address, 100000);
			await mockPool.connect(accountTarget).giveErc20(testTheTokenTarget.address, 200000);

			const accountProviderTokenBalance = await testTheTokenProvider.balanceOf(accountProvider.address);
			const accountTargetTokenBalance = await testTheTokenTarget.balanceOf(accountTarget.address);

			expect(accountProviderTokenBalance).to.equal(100000);
			expect(accountTargetTokenBalance).to.equal(200000);
		});



		it('create personal provider to the contract', async () => {
			// mint corresponding necessary token
			await testTheTokenProvider.mint(accountProvider.address, 100000);
			await testTheTokenTarget.mint(accountTarget.address, 200000);
			await testTheTokenFee.mint(accountProvider.address, 1000);

			// add new fee token with fee value only 10
			await mockPool.addTokenAddress(testTheTokenFee.address, 10);

			// approve account provider to contract to use 10000 fee from contract
			await testTheTokenFee.connect(accountProvider).approve(mockPool.address, 10000);
			// approve account provider to provider token from contract
			await testTheTokenProvider.connect(accountProvider).approve(mockPool.address, 100000);

			// create provider to provide 1000 TTP to exchange with 2000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				2000, 
				1
			);

			const ownerBalance = await testTheTokenFee.balanceOf(deployer.address);
			const providerBalance = await testTheTokenFee.balanceOf(accountProvider.address);
			const poolBalance = await testTheTokenProvider.balanceOf(mockPool.address);

			expect(ownerBalance).to.equal(10);
			expect(providerBalance).to.equal(990);
			expect(poolBalance).to.equal(1000);

			const allowance = await mockPool.connect(accountProvider).allowance(testTheTokenFee.address, accountProvider.address, mockPool.address);

			expect(allowance).to.equal(9990);

			const personalProviders = await mockPool.connect(accountProvider).getPersonalProvider(1, 1);
			const personalProvidersLength = await mockPool.connect(accountProvider).getPersonalProviderLength();

			expect(personalProviders.length).to.equal(1);
			expect(personalProvidersLength).to.equal(1);

			// create provider to provide 2000 TTP to exchange with 4000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				2000, 
				testTheTokenTarget.address,
				4000, 
				1
			);

			const personalProvidersLengthAfter = await mockPool.connect(accountProvider).getPersonalProviderLength();

			expect(personalProvidersLength).to.equal(1);
		});



		it('executing personal dex ', async () => {
			// mint corresponding necessary token
			await testTheTokenProvider.mint(accountProvider.address, 100000);
			await testTheTokenTarget.mint(accountTarget.address, 200000);
			await testTheTokenFee.mint(accountProvider.address, 1000);

			// add new fee token with fee value only 10
			await mockPool.addTokenAddress(testTheTokenFee.address, 10);

			// approve account provider to contract to use 10000 fee from contract
			await testTheTokenFee.connect(accountProvider).approve(mockPool.address, 10000);
			// approve account provider to provider token from contract
			await testTheTokenProvider.connect(accountProvider).approve(mockPool.address, 100000);

			// get balance of target token on contract
			const targetTokenBalanceBefore = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(targetTokenBalanceBefore).to.equal(0);

			// create provider to provide 1000 TTP to exchange with 2000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				2000, 
				1
			);

			// approve account target to target token from contract
			await testTheTokenTarget.connect(accountTarget).approve(mockPool.address, 100000);

			// fulfill the order of provider
			await mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0);

			// check contract balance after receive target token
			const targetTokenBalanceAfter = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(targetTokenBalanceAfter).to.equal(2000);

			// check account baalance before trade
			const accountProviderTTTBefore = await testTheTokenTarget.balanceOf(accountProvider.address);
			const accountTargetTTPBefore = await testTheTokenProvider.balanceOf(accountTarget.address);
			expect(accountProviderTTTBefore).to.equal(0);
			expect(accountTargetTTPBefore).to.equal(0);

			// execute the order
			await mockPool.connect(accountTarget).executePersonalTrade(accountProvider.address, 0);

			// check account baalance after trade
			const accountProviderTTTAfter = await testTheTokenTarget.balanceOf(accountProvider.address);
			const accountTargetTTPAfter = await testTheTokenProvider.balanceOf(accountTarget.address);
			expect(accountProviderTTTAfter).to.equal(2000);
			expect(accountTargetTTPAfter).to.equal(1000);

			// check provider data
			const currentProviderData = await mockPool.connect(accountProvider).getMyExchangeData();

			expect(currentProviderData.length).to.equal(0);

			// create 3 provider to provide 1000 TTP to exchange with 1000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				2000, 
				1
			);
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				3000, 
				1
			);
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				4000, 
				1
			);

			const currentProviderDataAfter = await mockPool.connect(accountProvider).getMyExchangeData();
			expect(currentProviderDataAfter.length).to.equal(3);

			// fulfill the order of provider
			await mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0);
			await mockPool.connect(accountTarget).executePersonalTrade(accountProvider.address, 0);

			const currentProviderDataAfterEx0 = await mockPool.connect(accountProvider).getMyExchangeData();
			expect(currentProviderDataAfterEx0[0].targetTokenValue).to.equal(4000);
			expect(currentProviderDataAfterEx0.length).to.equal(2);
		});
	});
	
	describe('Test Invalid Transaction for personal Dex', async () => {
		it('Create Personal Dex Provider invalid', async () => {
			// add new fee token with fee value only 10
			await mockPool.addTokenAddress(testTheTokenFee.address, 10);

			await expect(mockPool.connect(accountProvider).createPersonalProvider(
						testTheTokenProvider.address,
						1000, 
						testTheTokenTarget.address,
						2000, 
						1
					)
				)
			.to.be.revertedWith("Provider Token Balance not enough");

			await testTheTokenProvider.mint(accountProvider.address, 100000);

			await expect(mockPool.connect(accountProvider).createPersonalProvider(
						testTheTokenProvider.address,
						1000, 
						testTheTokenTarget.address,
						2000, 
						1
					)
				)
			.to.be.revertedWith("Provider token not enough allowance");

			await testTheTokenProvider.connect(accountProvider).approve(mockPool.address, 100000);

			await expect(mockPool.connect(accountProvider).createPersonalProvider(
						testTheTokenProvider.address,
						1000, 
						testTheTokenTarget.address,
						2000, 
						1
					)
				)
			.to.be.revertedWith("Provider fee token not enough allowance");

			// approve account provider to contract to use 10000 fee from contract
			await testTheTokenFee.connect(accountProvider).approve(mockPool.address, 10000);

			await expect(mockPool.connect(accountProvider).createPersonalProvider(
						testTheTokenProvider.address,
						1000, 
						testTheTokenTarget.address,
						2000, 
						1
					)
				)
			.to.be.revertedWith("Provider fee token Balance not enough");

			await testTheTokenFee.mint(accountProvider.address, 1000);

			await mockPool.connect(accountProvider).createPersonalProvider(
						testTheTokenProvider.address,
						1000, 
						testTheTokenTarget.address,
						2000, 
						1
					);
			
			const finalFeeBalanceProvider = await testTheTokenFee.balanceOf(accountProvider.address);
			expect(finalFeeBalanceProvider).to.equal(990);
		});

		it('Fulfill Order and trigger Invalid', async () => {
			// add new fee token with fee value only 10
			await mockPool.addTokenAddress(testTheTokenFee.address, 10);

			// select invalid index 2, since it still empty
			await expect(mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 2))
				.to.be.revertedWith("This execution is trying to execute index nothing");

			// provider try to fulfill it's own order
			await expect(mockPool.connect(accountProvider).fulfillPersonalTradeOrder(accountProvider.address, 2))
				.to.be.revertedWith("Provider can not fulfill own order");

			const balanceProviderTokenBefore = await testTheTokenProvider.balanceOf(mockPool.address);
			const balanceTargetTokenBefore = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(balanceProviderTokenBefore).to.equal(0);
			expect(balanceTargetTokenBefore).to.equal(0);

			// approve account provider to contract to use 10000 fee from contract
			await testTheTokenFee.connect(accountProvider).approve(mockPool.address, 10000);
			// approve account provider to provider token from contract
			await testTheTokenProvider.connect(accountProvider).approve(mockPool.address, 100000);
			// mint provider token to provider from contract
			await testTheTokenProvider.mint(accountProvider.address, 100000);
			// mint fee token to provider from contract
			await testTheTokenFee.mint(accountProvider.address, 1000);

			// create provider to provide 1000 TTP to exchange with 2000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				2000, 
				1
			);
			// allowance expected insufficient
			await expect(mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0))
				.to.be.revertedWith("Target token allowance target not enough");

			await testTheTokenTarget.connect(accountTarget).approve(mockPool.address, 100000);

			await expect(mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0))
				.to.be.revertedWith("Target Token Balance not enough");

			await testTheTokenTarget.mint(accountTarget.address, 200000);

			await mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0);

			const balanceProviderTokenAfter = await testTheTokenProvider.balanceOf(mockPool.address);
			const balanceTargetTokenAfter = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(balanceProviderTokenAfter).to.equal(1000);
			expect(balanceTargetTokenAfter).to.equal(2000);

			await expect(mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0))
				.to.be.revertedWith("This order was already fulfilled");
		});

		it('Execute Transaction and trigger invalid', async () => {
			// provider execute own provider order
			await expect(mockPool.connect(accountProvider).executePersonalTrade(accountProvider.address, 0))
				.to.be.revertedWith("Provider can not execute own order");

			// add new fee token with fee value only 10
			await mockPool.addTokenAddress(testTheTokenFee.address, 10);
			// approve account provider to contract to use 10000 fee from contract
			await testTheTokenFee.connect(accountProvider).approve(mockPool.address, 10000);
			// approve account provider to provider token from contract
			await testTheTokenProvider.connect(accountProvider).approve(mockPool.address, 100000);
			// mint provider token to provider from contract
			await testTheTokenProvider.mint(accountProvider.address, 100000);
			// mint fee token to provider from contract
			await testTheTokenFee.mint(accountProvider.address, 1000);
			await testTheTokenTarget.mint(accountTarget.address, 200000);
			await testTheTokenTarget.connect(accountTarget).approve(mockPool.address, 100000);

			// create provider to provide 1000 TTP to exchange with 2000 TTT and pay with fee index 1 token
			await mockPool.connect(accountProvider).createPersonalProvider(
				testTheTokenProvider.address,
				1000, 
				testTheTokenTarget.address,
				2000, 
				1
			);

			await mockPool.connect(accountTarget).fulfillPersonalTradeOrder(accountProvider.address, 0);

			// provider execute own provider order
			await expect(mockPool.connect(accountTarget).executePersonalTrade(accountProvider.address, 1))
				.to.be.revertedWith("This execution is trying to execute invalid index");

			// provider execute own provider order
			await expect(mockPool.connect(deployer).executePersonalTrade(accountProvider.address, 0))
				.to.be.revertedWith("This order is not for this address");

			const balanceProviderTokenBefore = await testTheTokenProvider.balanceOf(mockPool.address);
			const balanceTargetTokenBefore = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(balanceProviderTokenBefore).to.equal(1000);
			expect(balanceTargetTokenBefore).to.equal(2000);

			await mockPool.connect(accountTarget).executePersonalTrade(accountProvider.address, 0);

			const balanceProviderTokenAfter = await testTheTokenProvider.balanceOf(mockPool.address);
			const balanceTargetTokenAfter = await testTheTokenTarget.balanceOf(mockPool.address);
			expect(balanceProviderTokenAfter).to.equal(0);
			expect(balanceTargetTokenAfter).to.equal(0);

		});
	});
	describe('Test Cancellation on provider order', async () => {
		it('Execution Cancel Provider Order', async () => {
			
		});
	});
});


















