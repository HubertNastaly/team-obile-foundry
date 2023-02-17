pragma solidity ^0.8.18;

import "forge-std/console.sol";

import {TestExtended} from "test/utils/TestExtended.sol";

import {IERC20WithDecimals} from "src/interfaces/IERC20WithDecimals.sol";
import {LoanStatus} from "src/interfaces/IFixedInterestOnlyLoans.sol";
import {MockToken} from "src/mocks/MockToken.sol";
import {FixedInterestOnlyLoans} from "src/FixedInterestOnlyLoans.sol";

struct CreateLoanParams {
  address owner;
  IERC20WithDecimals asset;
  uint256 principal;
  uint16 periodCount;
  uint256 periodPayment;
  uint32 periodDuration;
  address recipient;
  uint32 gracePeriod;
  bool canBeRepaidAfterDefault;
}

abstract contract FixedInterestOnlyLoansUtils is TestExtended {
  FixedInterestOnlyLoans private fiol;
  MockToken private token;

  function initializeUtils(FixedInterestOnlyLoans _fiol, MockToken _token) internal {
    fiol = _fiol;
    token = _token;
  }

  function toWei(uint256 amount) internal view returns (uint256) {
    return toWei(amount, token.decimals());
  }

  function assertStatusEq(LoanStatus actual, LoanStatus expected) internal {
    assertTrue(actual == expected);
  }

  function getDefaultLoanParams() internal view returns (CreateLoanParams memory) {
    return CreateLoanParams({
      owner: defaultSender,
      asset: IERC20WithDecimals(address(token)),
      principal: toWei(1000),
      periodCount: 2,
      periodPayment: 100,
      periodDuration: 2 days,
      recipient: vm.addr(2_003),
      gracePeriod: 1 days,
      canBeRepaidAfterDefault: false
    });
  }

  function createLoan(CreateLoanParams memory params, address sender) from(sender) internal returns (uint256) {
    return createLoan(params);
  }

  function createLoan(CreateLoanParams memory params) internal returns (uint256) {
    return fiol.create(
      params.owner,
      params.asset,
      params.principal,
      params.periodCount,
      params.periodPayment,
      params.periodDuration,
      params.recipient,
      params.gracePeriod,
      params.canBeRepaidAfterDefault
    );
  }

  function acceptLoan(uint256 loanId, address sender) from(sender) internal {
    fiol.accept(loanId);
  }

  function startLoan(uint256 loanId) internal {
    fiol.start(loanId);
  }

  function createAcceptAndStart(CreateLoanParams memory params) internal returns (uint256) {
    uint256 loanId = createLoan(params);
    acceptLoan(loanId, params.recipient);
    startLoan(loanId);
    return loanId;
  }
}
