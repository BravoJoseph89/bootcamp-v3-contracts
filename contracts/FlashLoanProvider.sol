// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

interface IFlashLoanReceiver {
    function receiveFlashLoan(
        address token,
        uint256 amount,
        bytes memory _data
    ) external;
}

// We dont want to deploy this contract. We only want
// Our Exchantge contract to inherit this contract,
// thus we make it abstract
abstract contract FlashLoanProvider {
    event FlashLoan(address token, uint256 amount, uint256 timestamp);

    function flashLoan(
        address _token,
        uint256 _amount,
        bytes memory _data
    ) public {
        // Get our current token balance
        uint256 tokenBalanceBefore = Token(_token).balanceOf(address(this));

        // Require this contrtasct to have sufficient funds to send
        require(
            tokenBalanceBefore >= 0,
            "FlashLoanProvider: Insufficient funds to loan"
        );

        //Send funds to msg.sender
        require(
            Token(_token).transfer(msg.sender, _amount),
            "FlashLoanProvider: Transfer failed"
        );        

        // Call receiveFashLoan() on msg.sender
        IFlashLoanReceiver(msg.sender).receiveFlashLoan(_token, _amount, _data);

        // Get our token balance after
        uint256 tokenBalanceAfter = Token(_token).balanceOf(address(this));

        // Require this contract to have received back the funds
        require(
            tokenBalanceAfter >= tokenBalanceBefore,
            "FlashLoadProvider: Funds not received"
        );

        emit FlashLoan(_token, _amount, block.timestamp);
    }
}
