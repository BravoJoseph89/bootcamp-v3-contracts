// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

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
        // Send the money
        Token(_token).transfer(msg.sender, _amount);

        // Ask for money back

        // Ensure that money was paid back

        // Emit an Event
        emit FlashLoan(_token, _amount, block.timestamp);
    }
}
