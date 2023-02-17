pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20WithDecimals} from "src/interfaces/IERC20WithDecimals.sol";
import {FixedInterestOnlyLoansFixture} from "test/fixtures/FixedInterestOnlyLoansFixture.sol";
import {CreateLoanParams, FixedInterestOnlyLoansUtils} from "test/utils/FixedInterestOnlyLoansUtils.sol";

contract FixedInterestOnlyLoansTest is FixedInterestOnlyLoansFixture, Test {
  address immutable sender = vm.addr(1_001);

  FixedInterestOnlyLoansUtils private utils;

  function setUp() public {
    deploy(); // `deploy` once and use `vm.snapshot` with `vm.revertTo`
    utils = new FixedInterestOnlyLoansUtils(fiol);
    vm.startPrank(sender);
  }

  function testCreateRevertsAddressZero() public {
    CreateLoanParams memory params = utils.getDefaultLoanParams();
    params.recipient = address(0);

    vm.expectRevert(bytes('FIOL: Invalid recipient address'));
    utils.createLoan(params);
  }

  function testInitializeSetsNameAndSymbol() public {
    assertEq(fiol.name(), 'FixedInterestOnlyLoans');
    assertEq(fiol.symbol(), 'FIOL');
  }

  function testCreateLoan() public {
    CreateLoanParams memory params = utils.getDefaultLoanParams();
    uint256 loanId = utils.createLoan(params, sender);

    assertEq(fiol.creator(loanId), sender, "Creator");
    assertEq(fiol.principal(loanId), params.principal);
    assertEq(fiol.periodCount(loanId), params.periodCount);
    assertEq(fiol.periodPayment(loanId), params.periodPayment);
    assertEq(fiol.periodDuration(loanId), params.periodDuration);
    assertEq(fiol.recipient(loanId), params.recipient, "Recipient");
    assertEq(fiol.gracePeriod(loanId), params.gracePeriod);
    assertEq(fiol.canBeRepaidAfterDefault(loanId), params.canBeRepaidAfterDefault);
  }
}
