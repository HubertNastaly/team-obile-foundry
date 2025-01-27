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

import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {IFixedInterestOnlyLoans, ILoans} from "./IFixedInterestOnlyLoans.sol";
import {IERC20WithDecimals} from "./IERC20WithDecimals.sol";

/// @title Manager of a Structured Portfolio's active loans
interface ILoansManager {
    /**
     * @notice Event emitted when the loan is funded
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     */
    event LoanFunded(ILoans indexed loansContract, uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan is repaid
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     * @param amount Repaid amount
     */
    event LoanRepaid(ILoans indexed loansContract, uint256 indexed loanId, uint256 amount);

    /**
     * @notice Event emitted when the loan is marked as defaulted
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     */
    event LoanDefaulted(ILoans indexed loansContract, uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan grace period is updated
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     * @param newGracePeriod New loan grace period
     */
    event LoanGracePeriodUpdated(ILoans indexed loansContract, uint256 indexed loanId, uint32 newGracePeriod);

    /**
     * @notice Event emitted when the loan is cancelled
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     */
    event LoanCancelled(ILoans indexed loansContract, uint256 indexed loanId);

    /**
     * @notice Event emitted when the loan is fully repaid, cancelled or defaulted
     * @param loansContract Address of contract on which the loan has been created
     * @param loanId Loan id
     */
    event ActiveLoanRemoved(ILoans indexed loansContract, uint256 indexed loanId);

    event AllowedLoanChanged(ILoans indexed loansContract, bool isAllowed);

    /// @return Underlying asset address
    function asset() external view returns (IERC20WithDecimals);
}
