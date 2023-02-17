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

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {Upgradeable} from "./proxy/Upgradeable.sol";
import {IFixedInterestOnlyLoans, LoanStatus} from "./interfaces/IFixedInterestOnlyLoans.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";

contract FixedInterestOnlyLoans is ERC721Upgradeable, Upgradeable, IFixedInterestOnlyLoans {
    LoanMetadata[] internal loans;

    function initialize(IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
        __ERC721_init("FixedInterestOnlyLoans", "FIOL");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function principal(uint256 loanId) external view returns (uint256) {
        return loans[loanId].principal;
    }

    function asset(uint256 loanId) external view returns (IERC20WithDecimals) {
        return loans[loanId].asset;
    }

    function recipient(uint256 loanId) external view returns (address) {
        return loans[loanId].recipient;
    }

    function creator(uint256 loanId) external view returns (address) {
        return loans[loanId].creator;
    }

    function canBeRepaidAfterDefault(uint256 loanId) external view returns (bool) {
        return loans[loanId].canBeRepaidAfterDefault;
    }

    function status(uint256 loanId) external view returns (LoanStatus) {
        return loans[loanId].status;
    }

    function periodPayment(uint256 loanId) external view returns (uint256) {
        return loans[loanId].periodPayment;
    }

    function periodCount(uint256 loanId) external view returns (uint16) {
        return loans[loanId].periodCount;
    }

    function periodDuration(uint256 loanId) external view returns (uint32) {
        return loans[loanId].periodDuration;
    }

    function endDate(uint256 loanId) external view returns (uint256) {
        return loans[loanId].endDate;
    }

    function gracePeriod(uint256 loanId) external view returns (uint256) {
        return loans[loanId].gracePeriod;
    }

    function currentPeriodEndDate(uint256 loanId) external view returns (uint40) {
        return loans[loanId].currentPeriodEndDate;
    }

    function periodsRepaid(uint256 loanId) external view returns (uint256) {
        return loans[loanId].periodsRepaid;
    }

    function loanData(uint256 loanId) external view returns (LoanMetadata memory) {
        return loans[loanId];
    }

    function value(uint256 loanId) external view returns (uint256) {
        LoanMetadata memory loan = loans[loanId];

        if (loan.status != LoanStatus.Started) {
            return 0;
        }

        uint256 accruedInterest = _calculateAccruedInterest(
            loan.periodPayment,
            loan.periodDuration,
            loan.periodCount,
            loan.endDate,
            block.timestamp
        );
        uint256 interestPaidSoFar = loan.periodsRepaid * loan.periodPayment;

        if (loan.principal + accruedInterest <= interestPaidSoFar) {
            return 0;
        } else {
            return loan.principal + accruedInterest - interestPaidSoFar;
        }
    }

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
    ) public whenNotPaused returns (uint256) {
        require(_recipient != address(0), "FIOL: Invalid recipient address");

        uint32 loanDuration = _periodCount * _periodDuration;
        require(loanDuration > 0, "FIOL: Loan duration cannot be 0");

        uint256 _totalInterest = _periodCount * _periodPayment;
        require(_totalInterest > 0, "FIOL: Total interest cannot be 0");

        uint256 id = loans.length;
        loans.push(
            LoanMetadata(
                _principal,
                _periodPayment,
                LoanStatus.Created,
                _periodCount,
                _periodDuration,
                0, // currentPeriodEndDate
                _recipient,
                _canBeRepaidAfterDefault,
                0, // periodsRepaid
                _gracePeriod,
                0, // endDate,
                _asset,
                msg.sender // creator
            )
        );

        _safeMint(owner, id);

        emit LoanCreated(id);
        return id;
    }

    function accept(uint256 loanId) public whenNotPaused {
        _requireLoanStatus(loanId, LoanStatus.Created);
        require(msg.sender == loans[loanId].recipient, "FIOL: Not a borrower");
        _changeLoanStatus(loanId, LoanStatus.Accepted);
    }

    function start(uint256 loanId) external whenNotPaused {
        _requireLoanOwner(loanId);
        _requireLoanStatus(loanId, LoanStatus.Accepted);

        LoanMetadata storage loan = loans[loanId];
        _changeLoanStatus(loanId, LoanStatus.Started);

        uint32 _periodDuration = loan.periodDuration;
        uint40 loanDuration = loan.periodCount * _periodDuration;
        loan.endDate = uint40(block.timestamp) + loanDuration;
        loan.currentPeriodEndDate = uint40(block.timestamp + _periodDuration);
    }

    function _changeLoanStatus(uint256 loanId, LoanStatus _status) private {
        loans[loanId].status = _status;
        emit LoanStatusChanged(loanId, _status);
    }

    function repay(uint256 loanId, uint256 amount) public whenNotPaused returns (uint256 principalRepaid, uint256 interestRepaid) {
        _requireLoanOwner(loanId);
        require(_canBeRepaid(loanId), "FIOL: This loan cannot be repaid");

        LoanMetadata storage loan = loans[loanId];
        uint16 _periodsRepaid = loan.periodsRepaid;

        interestRepaid = loan.periodPayment;
        if (_periodsRepaid == loan.periodCount - 1) {
            principalRepaid = loan.principal;
            _changeLoanStatus(loanId, LoanStatus.Repaid);
        } else {
            loan.currentPeriodEndDate += loan.periodDuration;
        }
        require(amount == interestRepaid + principalRepaid, "FIOL: Invalid repayment amount");

        loan.periodsRepaid = _periodsRepaid + 1;

        emit LoanRepaid(loanId, amount);

        return (principalRepaid, interestRepaid);
    }

    function expectedRepaymentAmount(uint256 loanId) external view returns (uint256) {
        LoanMetadata storage loan = loans[loanId];
        uint256 amount = loan.periodPayment;
        if (loan.periodsRepaid == loan.periodCount - 1) {
            amount += loan.principal;
        }
        return amount;
    }

    function cancel(uint256 loanId) external whenNotPaused {
        _requireLoanOwner(loanId);
        LoanStatus _status = loans[loanId].status;
        require(_status == LoanStatus.Created || _status == LoanStatus.Accepted, "FIOL: Unexpected loan status");

        _changeLoanStatus(loanId, LoanStatus.Canceled);
    }

    function markAsDefaulted(uint256 loanId) external whenNotPaused {
        _requireLoanOwner(loanId);
        _requireLoanStatus(loanId, LoanStatus.Started);
        LoanMetadata storage loan = loans[loanId];
        require(loan.currentPeriodEndDate + loan.gracePeriod < block.timestamp, "FIOL: Too early to default");

        _changeLoanStatus(loanId, LoanStatus.Defaulted);
    }

    function updateGracePeriod(uint256 loanId, uint32 newGracePeriod) external whenNotPaused {
        _requireLoanOwner(loanId);
        _requireLoanStatus(loanId, LoanStatus.Started);
        LoanMetadata storage loan = loans[loanId];
        require(newGracePeriod > loan.gracePeriod, "FIOL: New grace period too short");

        loan.gracePeriod = newGracePeriod;

        emit LoanGracePeriodUpdated(loanId, newGracePeriod);
    }

    function _canBeRepaid(uint256 loanId) internal view returns (bool) {
        LoanMetadata storage loan = loans[loanId];

        return (loan.status == LoanStatus.Started) || (loan.status == LoanStatus.Defaulted && loan.canBeRepaidAfterDefault);
    }

    function _calculateAccruedInterest(
        uint256 _periodPayment,
        uint256 _periodDuration,
        uint256 _periodCount,
        uint256 _loanEndDate,
        uint256 _currentTimestamp
    ) internal pure returns (uint256) {
        uint256 fullInterest = _periodPayment * _periodCount;
        if (_currentTimestamp >= _loanEndDate) {
            return fullInterest;
        }

        uint256 loanDuration = _periodDuration * _periodCount;
        uint256 passed = _currentTimestamp + loanDuration - _loanEndDate;

        return (fullInterest * passed) / loanDuration;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenID
    ) internal override whenNotPaused {
        super._transfer(from, to, tokenID);
    }

    function _approve(address to, uint256 tokenID) internal override whenNotPaused {
        super._approve(to, tokenID);
    }

    function _requireLoanOwner(uint256 loanId) internal view {
        require(msg.sender == ownerOf(loanId), "FIOL: Not a loan owner");
    }

    function _requireLoanStatus(uint256 loanId, LoanStatus _status) internal view {
        require(loans[loanId].status == _status, "FIOL: Unexpected loan status");
    }
}
