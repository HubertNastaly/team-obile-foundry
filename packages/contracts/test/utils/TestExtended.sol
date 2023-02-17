pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

contract TestExtended is Test {
  address immutable defaultSender = vm.addr(1234);
  address internal currentPrank;

  function expectEmit() internal {
    vm.expectEmit(true, true, true, true);
  }

  function setNewPrank(address newPrank) internal {
    currentPrank = newPrank;
    changePrank(currentPrank);
  }

  modifier from(address sender) {
    address previousPrank = currentPrank;
    setNewPrank(sender);

    _;

    setNewPrank(previousPrank);
  }

  function toWei(uint256 amount, uint8 decimals) internal pure returns (uint256) {
    return amount * 10**decimals;
  }
}
