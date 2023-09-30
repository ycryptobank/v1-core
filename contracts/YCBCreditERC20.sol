// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts@4.8.3/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts@4.8.3/security/Pausable.sol";
// import "@openzeppelin/contracts@4.8.3/access/Ownable.sol";
// import "@openzeppelin/contracts@4.8.3/token/ERC20/extensions/draft-ERC20Permit.sol";
// import "@openzeppelin/contracts@4.8.3/token/ERC20/extensions/ERC20FlashMint.sol";

// /// @custom:security-contact info@ycryptobank.com
// contract YCBCredit is ERC20, Pausable, Ownable, ERC20Permit, ERC20FlashMint {
//     constructor() ERC20("YCBCredit", "YCBC") ERC20Permit("YCBCredit") {
//         _mint(msg.sender, 1000000 * 10 ** decimals());
//     }

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     function _beforeTokenTransfer(address from, address to, uint256 amount)
//         internal
//         whenNotPaused
//         override
//     {
//         super._beforeTokenTransfer(from, to, amount);
//     }
// }
