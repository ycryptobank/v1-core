const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Passport", () => {

    let poolOwner
    let passportPool
    let passport
    let customerAccount

    beforeEach(async () => {
        [ poolOwner, customerAccount ] = await ethers.getSigners();

        const _passportPool = await ethers.getContractFactory('YCBPassportPool');
        passportPool = await _passportPool.connect(poolOwner).deploy();
        
        const _passport = await ethers.getContractFactory('YCBPassport');
        passport = await _passport.connect(customerAccount).deploy(poolOwner.address, ethers.constants.AddressZero);
    })

    describe('Test YCB Passport Create', async () => {
        it('Create passport should show empty listAddress saved', async () => {
            const _listAddress = await passport.listAddress();
            expect(_listAddress.length).to.equal(0);
        })

        it('Create passport isValid should be false', async () => {
            const _isValid = await passport.isValid();
            expect(_isValid).false;
        })

        it('Create passport validate method should be not able to be called', async () => {
            await expect(
                passport.validate(ethers.utils.parseEther("49"))
            ).to.be.revertedWith('Only the passport pool owner can call this function')
        })
    })

    describe('Test YCB Passport addresses data', async () => {
        it('YCBPassport setAddress should set correctly and get the particular address', async () => {
            await passport.setAddresses("btc", "testbtcaddress");
            const _btcaddress = await passport.getAddresses("btc");
            expect(_btcaddress).to.equal("testbtcaddress");
            const _listAddress = await passport.listAddress();
            expect(_listAddress.length).to.equal(1);
        })
    })

    describe('Test YCB Passport addresses data', async () => {
        it('YCBPassport setAddress should set correctly and get the particular address', async () => {
            await passport.setAddresses("btc", "testbtcaddress");
            const _btcaddress = await passport.getAddresses("btc");
            expect(_btcaddress).to.equal("testbtcaddress");
            const _listAddress = await passport.listAddress();
            expect(_listAddress.length).to.equal(1);
        })
    })

    describe('Test YCB Passport migration', async () => {
        it('YCBPassport migrate to new contract should migrate the data', async () => {
            const _passport = await ethers.getContractFactory('YCBPassport', customerAccount);
            // user need to create new migrated contract first and call migrate to new contract, don't forget to input last passport address
            const newPassport = await _passport.deploy(poolOwner.address, passport.address);
            await newPassport.deployed();

            await passport.connect(customerAccount).setAddresses("btc", "btcAddress1");
            await passport.connect(customerAccount).setAddresses("eth", "ethAddress1");

            await passport.connect(customerAccount).migrate(newPassport.address);

            expect(await newPassport.getAddresses("btc")).to.equal("btcAddress1");
            expect(await newPassport.getAddresses("eth")).to.equal("ethAddress1");
            
        })
    })

    
})

describe("Test YCB Passport Pool", () => {

    let yieldOwner
    let customerAccount
    let flexibleYield

    beforeEach(async () => {
        [ yieldOwner, customerAccount ] = await ethers.getSigners();
        const _flexibleYield = await ethers.getContractFactory('YCBYieldFlexible');
        flexibleYield = await _flexibleYield(yieldOwner).deploy();
    })
})