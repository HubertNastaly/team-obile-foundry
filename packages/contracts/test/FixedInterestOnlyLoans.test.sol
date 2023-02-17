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

  function testCreateLoan() public {
    address owner = vm.addr(1);
    IERC20WithDecimals asset = IERC20WithDecimals(vm.addr(2));
    uint256 principal = 1000;
    uint16 periodCount = 2;
    uint256 periodPayment = 100;
    uint32 periodDuration = 2 days;
    address recipient = vm.addr(3);
    uint32 gracePeriod = 1 days;
    bool canBeRepaidAfterDefault = false;
    
    uint256 loanId = fiol.create(
      owner,
      asset,
      principal,
      periodCount,
      periodPayment,
      periodDuration,
      recipient,
      gracePeriod,
      canBeRepaidAfterDefault
    );

    assertEq(fiol.creator(loanId), address(this));
    assertEq(fiol.principal(loanId), principal);
    assertEq(fiol.periodCount(loanId), periodCount);
    assertEq(fiol.periodPayment(loanId), periodPayment);
    assertEq(fiol.periodDuration(loanId), periodDuration);
    assertEq(fiol.recipient(loanId), recipient);
    assertEq(fiol.gracePeriod(loanId), gracePeriod);
    assertEq(fiol.canBeRepaidAfterDefault(loanId), canBeRepaidAfterDefault);
  }
}
