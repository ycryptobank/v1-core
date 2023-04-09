const { expect } = require('chai');
const { ethers } = require('hardhat');

describe("Test Passport", () => {

    let poolOwner
    let passportPool
    let customerAccount

    beforeEach(async () => {
        [ poolOwner, customerAccount ] = await ethers.getSigners();

        const _passportPool = await ethers.getContractFactory('YCBPassportPool');
        passportPool = await _passportPool.connect(poolOwner).deploy();
    })

    describe('Test YCB Passport Pool Create', async () => {
        it('Create passport should add to passportList', async () => {
            const _getPassortBeforeCreate = await passportPool.connect(customerAccount).getMyPassport();
            expect(_getPassortBeforeCreate).to.equal(ethers.constants.AddressZero);
            await passportPool.connect(customerAccount).createPassport();
            const _getPassortAfterCreate = await passportPool.connect(customerAccount).getMyPassport();
            expect(_getPassortAfterCreate).to.not.equal(ethers.constants.AddressZero);
        })
    })

    describe('Test YCB Passport Pool Get My Passport', async () => {
        it('Get Remanining Credits', async () => {
            await passportPool.connect(customerAccount).getMyPassport();
            await passportPool.connect(customerAccount).createPassport();
            const _getMyPassportFromPool = await passportPool.connect(customerAccount).getMyPassport();
            const _getMyPassportContractInterface = await ethers.getContractFactory('YCBPassport');
            const _myPassport = await _getMyPassportContractInterface.attach(_getMyPassportFromPool);
            expect( await _myPassport.getRemainingCredits()).to.equal(0);
        })
    })
})

describe("Test Yield Flexible", () => {

    let yieldOwner
    let customerAccount
    let flexibleYield

    beforeEach(async () => {
        [ yieldOwner, customerAccount ] = await ethers.getSigners();
        const _flexibleYield = await ethers.getContractFactory('YCBYieldFlexible');
        flexibleYield = await _flexibleYield(yieldOwner).deploy();
    })
})