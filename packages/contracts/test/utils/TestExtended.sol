pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

contract TestExtended is Test {
  function expectEmit() internal {
    vm.expectEmit(true, true, true, true);
  }

  modifier from(address sender) {
    address previousSender = msg.sender;
    changePrank(sender);

    _;

    changePrank(previousSender);
  }
}
