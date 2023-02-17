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

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20WithDecimals} from "./IERC20WithDecimals.sol";

enum LoanStatus {
    Created,
    Accepted,
    Started,
    Repaid,
    Canceled,
    Defaulted
}

interface ILoans is IERC721Upgradeable {
    function principal(uint256 loanId) external view returns (uint256);

    function asset(uint256 loanId) external view returns (IERC20WithDecimals);

    function recipient(uint256 loanId) external view returns (address);

    function creator(uint256 loanId) external view returns (address);

    function endDate(uint256 loanId) external view returns (uint256);

    function value(uint256 loanId) external view returns (uint256);

    function repay(uint256 loanId, uint256 amount) external returns (uint256 principalRepaid, uint256 interestRepaid);

    function start(uint256 loanId) external;

    function cancel(uint256 loanId) external;

    function markAsDefaulted(uint256 loanId) external;

    function status(uint256 loanId) external view returns (LoanStatus);

    function expectedRepaymentAmount(uint256 loanId) external view returns (uint256);

    function canBeRepaidAfterDefault(uint256 loanId) external view returns (bool);

    function gracePeriod(uint256 loanId) external view returns (uint256);

    function updateGracePeriod(uint256 loanId, uint32 newGracePeriod) external;
}
