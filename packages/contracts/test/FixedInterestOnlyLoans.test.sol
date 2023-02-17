pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/FixedInterestOnlyLoans.sol";
import "../src/ProtocolConfig.sol";
import "../src/interfaces/IERC20WithDecimals.sol";
import "../src/proxy/ProxyWrapper.sol";

contract FixedInterestOnlyLoansTest is Test {
  FixedInterestOnlyLoans internal fiolImplementation;
  ProtocolConfig internal protocolConfig;


  function setUp() public {
    fiolImplementation = new FixedInterestOnlyLoans();
    protocolConfig = new ProtocolConfig();
  }

  function testCreateRevertsAddressZero() public {
    vm.expectRevert(bytes('FIOL: Invalid recipient address'));
    fiolImplementation.create(
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
    FixedInterestOnlyLoans fiol = FixedInterestOnlyLoans(
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
    assertEq(fiol.name(), 'FixedInterestOnlyLoans');
    assertEq(fiol.symbol(), 'FIOL');
  }
}
