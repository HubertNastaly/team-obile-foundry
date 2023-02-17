pragma solidity ^0.8.18;

import {FixedInterestOnlyLoansDeploy} from "test/fixtures/FixedInterestOnlyLoansDeploy.sol";
import {FixedInterestOnlyLoansUtils} from "test/fixtures/FixedInterestOnlyLoansUtils.sol";

contract FixedInterestOnlyLoansFixture is FixedInterestOnlyLoansDeploy, FixedInterestOnlyLoansUtils {
  address immutable sender = vm.addr(1_001);

  function loadFixture() internal {
    deploy(); // `deploy` once and use `vm.snapshot` with `vm.revertTo`
    initializeUtils(fiol, token);

    vm.startPrank(sender);
  }
}
