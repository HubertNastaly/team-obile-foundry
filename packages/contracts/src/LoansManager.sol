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
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {LoanStatus, ILoans} from "./interfaces/ILoans.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {ILoansManager} from "./interfaces/ILoansManager.sol";

/// @title Manager of portfolio's active loans
abstract contract LoansManager is ILoansManager {
    using SafeERC20 for IERC20WithDecimals;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal allowedLoansContract;
    IERC20WithDecimals public asset;

    EnumerableSet.UintSet internal activeLoanIds;
    mapping(uint256 => bool) public fundedLoanIds;

    function _initialize(IERC20WithDecimals _asset, ILoans[] calldata _allowedLoansContracts) internal {
        asset = _asset;
        for (uint256 i = 0; i < _allowedLoansContracts.length; i++) {
            _setAllowedLoansContract(_allowedLoansContracts[i], true);
        }
    }

    function allowedLoansContracts() external view returns (address[] memory) {
        return allowedLoansContract.values();
    }

    function _setAllowedLoansContract(ILoans loansContract, bool isAllowed) internal {
        require(address(loansContract) != address(0), "LM: Invalid loans address");
        require(allowedLoansContract.contains(address(loansContract)) != isAllowed, "LM: Only different value");

        if (isAllowed) {
            allowedLoansContract.add(address(loansContract));
        } else {
            allowedLoansContract.remove(address(loansContract));
        }

        emit AllowedLoanChanged(loansContract, isAllowed);
    }

    function _markLoanAsDefaulted(ILoans loansContract, uint256 loanId) internal {
        loansContract.markAsDefaulted(loanId);
        _tryToExcludeLoan(loansContract, loanId);
        emit LoanDefaulted(loansContract, loanId);
    }

    function _fundLoan(ILoans loansContract, uint256 loanId) internal returns (uint256 principal) {
        _requireAllowedLoansContract(loansContract);
        require(loansContract.ownerOf(loanId) == address(this), "LM: Not a loan owner");

        principal = loansContract.principal(loanId);
        require(asset.balanceOf(address(this)) >= principal, "LM: Insufficient funds");

        loansContract.start(loanId);

        uint256 globalId = _globalLoanId(loansContract, loanId);
        activeLoanIds.add(globalId);
        fundedLoanIds[globalId] = true;
        address borrower = loansContract.recipient(loanId);
        asset.safeTransfer(borrower, principal);

        emit LoanFunded(loansContract, loanId);
    }

    function _repayLoan(ILoans loansContract, uint256 loanId) internal returns (uint256 amount) {
        amount = _repayLoanOnLoansContract(loansContract, loanId);
        asset.safeTransferFrom(msg.sender, address(this), amount);
        emit LoanRepaid(loansContract, loanId, amount);
    }

    function _updateLoanGracePeriod(
        ILoans loansContract,
        uint256 loanId,
        uint32 newGracePeriod
    ) internal {
        loansContract.updateGracePeriod(loanId, newGracePeriod);
        emit LoanGracePeriodUpdated(loansContract, loanId, newGracePeriod);
    }

    function _cancelLoan(ILoans loansContract, uint256 loanId) internal {
        loansContract.cancel(loanId);
        emit LoanCancelled(loansContract, loanId);
    }

    function _loansValue() internal view returns (uint256) {
        uint256[] memory _loans = activeLoanIds.values();

        uint256 _value = 0;
        for (uint256 i = 0; i < _loans.length; i++) {
            _value += _globalIdToLoansContract(_loans[i]).value(_globalIdToLoanId(_loans[i]));
        }

        return _value;
    }

    function _repayLoanOnLoansContract(ILoans loansContract, uint256 loanId) internal returns (uint256) {
        require(fundedLoanIds[_globalLoanId(loansContract, loanId)], "LM: Not funded by this contract");
        require(loansContract.recipient(loanId) == msg.sender, "LM: Not an instrument recipient");

        uint256 amount = loansContract.expectedRepaymentAmount(loanId);
        loansContract.repay(loanId, amount);
        _tryToExcludeLoan(loansContract, loanId);

        return amount;
    }

    function _tryToExcludeLoan(ILoans loansContract, uint256 loanId) internal {
        LoanStatus loanStatus = loansContract.status(loanId);

        if (loanStatus == LoanStatus.Started || loanStatus == LoanStatus.Accepted || loanStatus == LoanStatus.Created) {
            return;
        }

        uint256 globalId = _globalLoanId(loansContract, loanId);
        bool isLoanRemoved = activeLoanIds.remove(globalId);
        if (isLoanRemoved) {
            emit ActiveLoanRemoved(loansContract, loanId);
        }
    }

    function _calculateAccruedInterest(
        uint256 periodPayment,
        uint256 periodDuration,
        uint256 periodCount,
        uint256 loanEndDate
    ) internal view returns (uint256) {
        uint256 fullInterest = periodPayment * periodCount;
        if (block.timestamp >= loanEndDate) {
            return fullInterest;
        }

        uint256 loanDuration = (periodDuration * periodCount);
        uint256 passed = block.timestamp + loanDuration - loanEndDate;

        return (fullInterest * passed) / loanDuration;
    }

    function _requireAllowedLoansContract(ILoans loansContract) internal view {
        require(allowedLoansContract.contains(address(loansContract)), "LM: Loans contract not allowed");
    }

    function _globalLoanId(ILoans loansContract, uint256 loanId) internal pure returns (uint256) {
        return ((uint256(uint160(address(loansContract)))) << 96) + loanId;
    }

    function _globalIdToLoansContract(uint256 globalId) internal pure returns (ILoans) {
        return ILoans(address(uint160(globalId >> 96)));
    }

    function _globalIdToLoanId(uint256 globalId) internal pure returns (uint256) {
        return globalId & ((1 << 96) - 1);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
