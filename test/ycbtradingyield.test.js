const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Trading Yield Contract", () => {

    let tokenYield;
    let tokenStake;
    let yieldContract;
    let staker;
    let poolOwner;

    beforeEach(async () => {
        [staker, poolOwner] = await ethers.getSigners();
        const _providerToken = await ethers.getContractFactory('ERC20PresetMinterPauser');
        tokenYield = await _providerToken.connect(poolOwner).deploy("TokenYield", "TY");
        tokenStake = await _providerToken.connect(poolOwner).deploy("TokenStake", "TS");
        await tokenYield.deployed();
		await tokenStake.deployed();
        const _yieldContract = await ethers.getContractFactory("YCBTradingYield");
        yieldContract = await _yieldContract.connect(poolOwner).deploy(tokenStake.address, tokenYield.address, ethers.utils.parseEther("10000"));
        await yieldContract.deployed();
        await tokenYield.connect(poolOwner).approve(yieldContract.address, ethers.utils.parseEther("10"));
        await tokenYield.connect(poolOwner).mint(poolOwner.address, ethers.utils.parseEther("10"));
        await tokenStake.connect(staker).approve(yieldContract.address, ethers.utils.parseEther("10"));
        await tokenStake.connect(poolOwner).mint(staker.address, ethers.utils.parseEther("10"));
    })

    it("Should Return 0 when startDepositTime is 0", async () => {
        expect(await yieldContract.getYieldAPR()).to.equal(0);
	})

    it("Should return correct stake and unstake value when triggered", async () => {
        var _totalStake = await yieldContract.totalStaked();
        expect(ethers.utils.formatEther(_totalStake).toString()).to.equal("0.0");
        expect(await yieldContract.connect(staker).stake(ethers.utils.parseEther("10"))).to.not.be.reverted;
        _totalStake = await yieldContract.totalStaked();
        expect(ethers.utils.formatEther(_totalStake).toString()).to.equal("10.0");
        expect(await yieldContract.connect(staker).unstake(ethers.utils.parseEther("10"))).to.not.be.reverted;
        _totalStake = await yieldContract.totalStaked();
        expect(ethers.utils.formatEther(_totalStake).toString()).to.equal("0.0");
	})

    it("Should return correct total OwnerDeposit corresponding to deposit from owner", async () => {
        var _ownerDeposit = await yieldContract.ownerDeposit();
        expect(ethers.utils.formatEther(_ownerDeposit).toString()).to.equal("0.0");
        expect(await yieldContract.connect(poolOwner).deposit(ethers.utils.parseEther("10"))).to.not.be.reverted;
        _ownerDeposit = await yieldContract.ownerDeposit();
        expect(ethers.utils.formatEther(_ownerDeposit).toString()).to.equal("10.0");
	})

    it("Should return quantity of APR token corresponding to deposit from owner", async () => {
        var _yieldAPR = await yieldContract.getYieldAPR();
        expect(ethers.utils.formatEther(_yieldAPR).toString()).to.equal("0.0");
        await yieldContract.connect(poolOwner).deposit(ethers.utils.parseEther("10"));
        _yieldAPR = await yieldContract.getYieldAPR();
        expect(ethers.utils.formatEther(_yieldAPR).toString()).to.equal("3650.0"); 
        await ethers.provider.send("evm_increaseTime", [86400]);
        await ethers.provider.send("evm_mine");
        await ethers.provider.send("evm_increaseTime", [86400]);
        await ethers.provider.send("evm_mine");
        _yieldAPR = await yieldContract.getYieldAPR();
        expect(ethers.utils.formatEther(_yieldAPR).toString()).to.equal("1825.0"); 
	})

    it("Should not allow user to stake when pause only unstake", async () => {
        await expect(yieldContract.connect(poolOwner).deposit(ethers.utils.parseEther("10"))).to.not.be.reverted;
        await expect(yieldContract.connect(poolOwner).pauseStaking()).to.not.be.reverted;
        await expect(yieldContract.connect(staker).stake(ethers.utils.parseEther("10"))).to.be.reverted;
        await expect(yieldContract.connect(poolOwner).unpauseStaking()).to.not.be.reverted;
        await expect(yieldContract.connect(staker).stake(ethers.utils.parseEther("10"))).to.not.be.reverted;
        let _totalStake = await yieldContract.totalStaked();
        expect(ethers.utils.formatEther(_totalStake).toString()).to.equal("10.0");
	})

})