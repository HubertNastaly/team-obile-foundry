// SPDX-License-Identifier: BUSL-1.1
// Business Source License 1.1
// License text copyright (c) 2017 MariaDB Corporation Ab, All Rights Reserved. "Business Source License" is a trademark of MariaDB Corporation Ab.

// Parameters
// Licensor: TrueFi Foundation Ltd.
// Licensed Work: Structured Credit Vaults. The Licensed Work is (c) 2022 TrueFi Foundation Ltd.
// Additional Use Grant: Any uses listed and defined at this [LICENSE](https://github.com/trusttoken/contracts-carbon/license.md)
// Change Date: December 31, 2025
// Change License: MIT

pragma solidity ^0.8.16;

import {ILoans, LoanStatus} from "./ILoans.sol";
import {IERC20WithDecimals} from "./IERC20WithDecimals.sol";
import {IProtocolConfig} from "./IProtocolConfig.sol";

interface IFixedInterestOnlyLoans is ILoans {
    struct LoanMetadata {
        uint256 principal;
        uint256 periodPayment;
        LoanStatus status;
        uint16 periodCount;
        uint32 periodDuration;
        uint40 currentPeriodEndDate;
        address recipient;
        bool canBeRepaidAfterDefault;
        uint16 periodsRepaid;
        uint32 gracePeriod;
        uint40 endDate;
        IERC20WithDecimals asset;
        address creator;
    }

    event LoanCreated(uint256 indexed loanId);

    event LoanStatusChanged(uint256 indexed loanId, LoanStatus newStatus);

    event LoanGracePeriodUpdated(uint256 indexed loanId, uint32 newGracePeriod);

    event LoanRepaid(uint256 indexed loanId, uint256 amount);

    function create(
        address owner,
        IERC20WithDecimals _asset,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod,
        bool _canBeRepaidAfterDefault
    ) external returns (uint256);

    function loanData(uint256 loanId) external view returns (LoanMetadata memory);

    function updateGracePeriod(uint256 loanId, uint32 gracePeriod) external;

    function initialize(IProtocolConfig _protocolConfig) external;
}
