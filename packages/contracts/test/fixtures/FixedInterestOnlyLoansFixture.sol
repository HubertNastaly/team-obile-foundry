pragma solidity ^0.8.18;

import {FixedInterestOnlyLoans, IFixedInterestOnlyLoans} from "src/FixedInterestOnlyLoans.sol";
import {ProtocolConfig} from "src/ProtocolConfig.sol";
import {ProxyWrapper} from "src/proxy/ProxyWrapper.sol";

abstract contract FixedInterestOnlyLoansFixture {
  FixedInterestOnlyLoans internal fiol;

  function deploy() public {
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
  }
}
