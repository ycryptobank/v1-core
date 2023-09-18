const { expect, util } = require('chai');
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
        passport = await _passport.connect(customerAccount).deploy(passportPool.address, ethers.constants.AddressZero);
    })

    describe('Test YCB Passport Create', async () => {
        it('Create passport should show empty listAddress saved', async () => {
            const _listAddress = await passport.listAddress();
            expect(_listAddress.length).to.equal(0);
        })

        it('Create passport isValid should be false', async () => {
            const _isValid = await passport.isValid();
            expect(_isValid).to.equal(false);
        })

        it('Create passport validate should reflect isValid true', async () => {
            const _isValid = await passport.isValid();
            expect(_isValid).to.equal(false);

            await expect(
                passport.validate(ethers.utils.parseEther("49"), { value: ethers.utils.parseEther("50") })
            ).to.not.be.reverted;

            const _isValidAfter = await passport.isValid();
            expect(_isValidAfter).to.equal(true);
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

    let poolOwner
    let customerAccount
    let passportPool
    let passport

    beforeEach(async () => {
        [ poolOwner, customerAccount ] = await ethers.getSigners();
        const _passportPool = await ethers.getContractFactory('YCBPassportPool');
        passportPool = await _passportPool.connect(poolOwner).deploy();
        
        const _passport = await ethers.getContractFactory('YCBPassport');
        passport = await _passport.connect(customerAccount).deploy(passportPool.address, ethers.constants.AddressZero);
    })

    describe('Test YCB Passport Pool methods', async () => {

        it('YCBPassport Pool set price', async () => {
            const _price = await passportPool.validationPrice();
            console.log(`price: ${ethers.utils.formatEther(_price).toString()}`);
            expect(ethers.utils.formatEther(_price).toString()).to.equal("49.0");
            
            await passportPool.connect(poolOwner).setValidationPrice(ethers.utils.parseEther("1.0"));
            const _updatedPrice = await passportPool.validationPrice();
            expect(ethers.utils.formatEther(_updatedPrice).toString()).to.equal("1.0");
        })

        it('YCBPassport Pool getValidatedMember status should reflect correctly', async () => {
            const _isValid = await passportPool.getValidatedMember(passport.address);
            expect(_isValid).false;
            await expect(
                passport.validate(ethers.utils.parseEther("49"), { value: ethers.utils.parseEther("50") })
            ).to.not.be.reverted;
            const _isValidAfter = await passportPool.getValidatedMember(passport.address);
            expect(_isValidAfter).true;
        })

        it('YCBPassport Pool revalidate should copy date correctly', async () => {
            const _date = await passportPool.getValidatedMemberDate(passport.address);
            expect(_date).to.equal(0);

            await expect(
                passport.validate(ethers.utils.parseEther("49"), { value: ethers.utils.parseEther("50") })
            ).to.not.be.reverted;

            const _dateAfter = await passportPool.getValidatedMemberDate(passport.address);
            console.log(`dateAfter: ${_dateAfter.toString()}`);
            expect(parseInt(_dateAfter)).to.greaterThanOrEqual(0);

            const _passport = await ethers.getContractFactory('YCBPassport', customerAccount);
            const newPassport = await _passport.deploy(poolOwner.address, passport.address);
            await newPassport.deployed();

            const _dateNew = await passportPool.getValidatedMemberDate(newPassport.address);
            expect(_dateNew).to.equal(0);

            await passportPool.connect(poolOwner).revalidate(newPassport.address, passport.address);

            const _dateNewAfter = await passportPool.getValidatedMemberDate(newPassport.address);
            expect(parseInt(_dateNewAfter)).to.greaterThanOrEqual(0);
        })

        it('YCBPassport Pool should allow owner to withdraw', async () => {

            const balance = await ethers.provider.getBalance(passportPool.address);
            console.log(`Balance: ${balance.toString()}`);
            expect(balance).to.equal("0");

            await expect(
                passport.validate(ethers.utils.parseEther("49"), { value: ethers.utils.parseEther("49.1") })
            ).to.not.be.reverted;

            const balanceOwner = await ethers.provider.getBalance(poolOwner.address);
            console.log(`BalanceOwner: ${ethers.utils.formatEther(balanceOwner).toString()}`);

            const balance2 = await ethers.provider.getBalance(passportPool.address);
            console.log(`Balance: ${balance2.toString()}`);
            expect(ethers.utils.formatEther(balance2).toString()).to.equal("49.1");

            await passportPool.connect(poolOwner).withdraw(poolOwner.address, ethers.utils.parseEther("1.0"))

            const balanceOwner2 = await ethers.provider.getBalance(poolOwner.address);
            console.log(`BalanceOwner2: ${ethers.utils.formatEther(balanceOwner2).toString()}`);
            expect(parseInt(ethers.utils.formatEther(balanceOwner2).toString())).to.greaterThanOrEqual(10000000);
            
        })
    })
})