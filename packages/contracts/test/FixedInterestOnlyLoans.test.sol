pragma solidity ^0.8.18;

import {FixedInterestOnlyLoansFixture} from "test/fixtures/FixedInterestOnlyLoansFixture.sol";
import {CreateLoanParams} from "test/fixtures/FixedInterestOnlyLoansUtils.sol";

import {IERC20WithDecimals} from "src/interfaces/IERC20WithDecimals.sol";
import {LoanStatus} from "src/interfaces/IFixedInterestOnlyLoans.sol";

contract FixedInterestOnlyLoansTest is FixedInterestOnlyLoansFixture {
  event LoanCreated(uint256 indexed loanId);

  function setUp() public {
    loadFixture();
  }

  function testCreateRevertsAddressZero() public {
    CreateLoanParams memory params = getDefaultLoanParams();
    params.recipient = address(0);

    vm.expectRevert(bytes('FIOL: Invalid recipient address'));
    createLoan(params);
  }

  function testInitializeSetsNameAndSymbol() public {
    assertEq(fiol.name(), 'FixedInterestOnlyLoans');
    assertEq(fiol.symbol(), 'FIOL');
  }

  function testCreateLoan() public {
    CreateLoanParams memory params = getDefaultLoanParams();
    uint256 loanId = createLoan(params);

    assertEq(fiol.creator(loanId), defaultSender);
    assertEq(fiol.principal(loanId), params.principal);
    assertEq(fiol.periodCount(loanId), params.periodCount);
    assertEq(fiol.periodPayment(loanId), params.periodPayment);
    assertEq(fiol.periodDuration(loanId), params.periodDuration);
    assertEq(fiol.recipient(loanId), params.recipient);
    assertEq(fiol.gracePeriod(loanId), params.gracePeriod);
    assertEq(fiol.canBeRepaidAfterDefault(loanId), params.canBeRepaidAfterDefault);
  }

  function testCreateEmits() public {
    CreateLoanParams memory params = getDefaultLoanParams();

    expectEmit();
    emit LoanCreated(0);
    createLoan(params);
  }

  function testAcceptLoanSetsAcceptedStatus() public {
    CreateLoanParams memory params = getDefaultLoanParams();
    uint256 loanId = createLoan(params);

    acceptLoan(loanId, params.recipient);

    assertStatusEq(fiol.status(loanId), LoanStatus.Accepted);
  }

  function testStartLoan() public {
    CreateLoanParams memory params = getDefaultLoanParams();
    uint256 loanId = createAcceptAndStart(params);
    assertStatusEq(fiol.status(loanId), LoanStatus.Started);
  }

  function testStartRevertsNonOwner() public {
    CreateLoanParams memory params = getDefaultLoanParams();
    uint256 loanId = createLoan(params);

    acceptLoan(loanId, params.recipient);

    setNewPrank(vm.addr(3_001));
    vm.expectRevert(bytes("FIOL: Not a loan owner"));
    startLoan(loanId);
  }
}
