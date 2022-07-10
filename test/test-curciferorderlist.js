const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Curcifer Order", () => {
	let deployer
	let providerToken
	let desiredToken

	beforeEach(async () => {
		deployer = await ethers.getSigners();
		const _providerToken = await ethers.getContractFactory('ERC20PresetMinterPauser');
		providerToken = await _providerToken.deploy("ProviderToken", "PT");
		await providerToken.deployed();
	})

	describe("Test New Order Creation", async () => {
		it("create new order", async () => {

		})
	})
})