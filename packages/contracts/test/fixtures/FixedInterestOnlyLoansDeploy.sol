pragma solidity ^0.8.18;

import {MockToken} from "src/mocks/MockToken.sol";
import {ProxyWrapper} from "src/proxy/ProxyWrapper.sol";
import {FixedInterestOnlyLoans, IFixedInterestOnlyLoans} from "src/FixedInterestOnlyLoans.sol";
import {ProtocolConfig} from "src/ProtocolConfig.sol";

abstract contract FixedInterestOnlyLoansDeploy {
  uint8 constant private tokenDecimals = 8;

  FixedInterestOnlyLoans internal fiol;
  MockToken internal token;

  function deploy() internal {
    FixedInterestOnlyLoans fiolImplementation = new FixedInterestOnlyLoans();
    ProtocolConfig protocolConfig = new ProtocolConfig();

    fiol = FixedInterestOnlyLoans(
      address(
        new ProxyWrapper(
          address(fiolImplementation),
          abi.encodeWithSelector(
            IFixedInterestOnlyLoans.initialize.selector,
            protocolConfig
          )
        )
      )
    );

    token = new MockToken(tokenDecimals);
  }
}
