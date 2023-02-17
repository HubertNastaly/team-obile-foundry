pragma solidity ^0.8.18;

import {FixedInterestOnlyLoansDeploy} from "test/fixtures/FixedInterestOnlyLoansDeploy.sol";
import {FixedInterestOnlyLoansUtils} from "test/fixtures/FixedInterestOnlyLoansUtils.sol";

contract FixedInterestOnlyLoansFixture is FixedInterestOnlyLoansDeploy, FixedInterestOnlyLoansUtils {
  function loadFixture() internal {
    deploy(); // `deploy` once and use `vm.snapshot` with `vm.revertTo`
    initializeUtils(fiol, token);

    setNewPrank(defaultSender);
  }
}
