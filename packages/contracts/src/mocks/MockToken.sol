// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    uint8 public _decimals;
    mapping(address => bool) public isTransferToFailing;
    mapping(address => bool) public isTransferFromFailing;
    mapping(address => bool) public isApprovalFailing;

    constructor(uint8 __decimals) ERC20("MockToken", "MOCK") {
        _decimals = __decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function setFailingTransfersTo(address to, bool shouldFail) external {
        isTransferToFailing[to] = shouldFail;
    }

    function setFailingTransfersFrom(address from, bool shouldFail) external {
        isTransferFromFailing[from] = shouldFail;
    }

    function setFailingApprovesFrom(address owner, bool shouldFail) external {
        isApprovalFailing[owner] = shouldFail;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (isTransferToFailing[to]) {
            revert("MockToken: Transfer failed");
        } else {
            return super.transfer(to, amount);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (isTransferToFailing[to]) {
            revert("MockToken: Transfer failed");
        } else {
            return super.transferFrom(from, to, amount);
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (isApprovalFailing[msg.sender]) {
            revert("MockToken: Approve failed");
        } else {
            return super.approve(spender, amount);
        }
    }
}
