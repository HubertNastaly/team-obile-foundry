pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/FixedInterestOnlyLoans.sol";
import "../src/interfaces/IERC20WithDecimals.sol";

contract FixedInterestOnlyLoansTest is Test {
  FixedInterestOnlyLoans internal fiol;

  function setUp() public {
    fiol = new FixedInterestOnlyLoans();
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
}
