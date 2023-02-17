pragma solidity ^0.8.18;

import {TestExtended} from "test/utils/TestExtended.sol";

import {FixedInterestOnlyLoans} from "src/FixedInterestOnlyLoans.sol";
import {MockToken} from "src/mocks/MockToken.sol";
import {IERC20WithDecimals} from "src/interfaces/IERC20WithDecimals.sol";

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

contract FixedInterestOnlyLoansUtils is TestExtended {
  FixedInterestOnlyLoans immutable fiol;
  MockToken immutable token;

  constructor(FixedInterestOnlyLoans _fiol, MockToken _token) {
    fiol = _fiol;
    token = _token;
  }

  function toWei(uint256 amount) public view returns (uint256) {
    return toWei(amount, token.decimals());
  }

  function createLoan(CreateLoanParams memory params) external returns (uint256) {
    return _createLoan(params);
  }

  function createLoan(CreateLoanParams memory params, address sender) from(sender) external returns (uint256) {
    return _createLoan(params);
  }

  function _createLoan(CreateLoanParams memory params) private returns (uint256) {
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

  function getDefaultLoanParams() external view returns (CreateLoanParams memory) {
    return CreateLoanParams({
      owner: vm.addr(2_001),
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
}
