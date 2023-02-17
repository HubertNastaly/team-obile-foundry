pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {IERC20WithDecimals} from "src/interfaces/IERC20WithDecimals.sol";
import {FixedInterestOnlyLoansFixture} from "test/fixtures/FixedInterestOnlyLoansFixture.sol";

contract FixedInterestOnlyLoansTest is FixedInterestOnlyLoansFixture, Test {
  function setUp() public {
    deploy();
  }

  function testCreateRevertsAddressZero() public {
    vm.expectRevert(bytes('FIOL: Invalid recipient address'));
    fiol.create(
      address(0),
      IERC20WithDecimals(address(0)),
      0,
      0,
      0,
      0,
      address(0),
      0,
      false
    );
  }

  function testInitializeSetsNameAndSymbol() public {
    assertEq(fiol.name(), 'FixedInterestOnlyLoans');
    assertEq(fiol.symbol(), 'FIOL');
  }
}
