// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Token} from "./Token.sol";

contract Exchange {
    // State variables
    address public feeAccount;
    uint256 public feePercent;
    uint256 public orderCount;

    // Mappings
    mapping(uint256 => Order) public orders;
    mapping(uint256 => bool) public isOrderCancelled;

    // Total tokens belonging to a user
    mapping(address => mapping(address => uint256))
        private userTotalTokenBalance;
    // Total tokens on an active order
    mapping(address => mapping(address => uint256))
        private userActiveTokenBalance;

    
    // Events
    event TokensDeposited(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );
    event TokensWithdrawn(
        address token,
        address user,
        uint256 amount,
        uint256 balance
    );
    event OrderCreated(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event OrderCancelled(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    struct Order{
        // Attributes of an order
        uint256 id; // Unique identifier for order
        address user; // User who made the order
        address tokenGet; // Address of the token they receive
        uint256 amountGet; // Amount they receive
        address tokenGive; // Address of the token they give
        uint256 amountGive; // Amount they give
        uint256 timestamp; // When order was created
    }
    
    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }


    //------------------------
    // DEPOSIT & WITHDRAW TOKEN

    function depositToken(address _token, uint256 _amount)  public {
        // Update user balance
        userTotalTokenBalance[_token] [msg.sender] += _amount;

        // Emit an event
        emit TokensDeposited(
            _token,
            msg.sender,
            _amount,
            userTotalTokenBalance[_token] [msg.sender]
        );

        // Transfer tokens to exchange
        require(
            Token(_token).transferFrom(msg.sender, address(this), _amount),
            "Exchange: Token Transfer failed"
        );        
    }

    function withdrawToken(address _token, uint256 _amount)  public {
        require(
            totalBalanceOf(_token,msg.sender) -
                activeBalanceOf(_token,msg.sender) >= 
                _amount,
            "Exchange: Insufficient balance"
        );

        // Update the user balance
        userTotalTokenBalance[_token] [msg.sender] -= _amount;

        // Emit an Event
        emit TokensWithdrawn(
            _token,
            msg.sender,
            _amount,
            userTotalTokenBalance[_token] [msg.sender]
        );

        // Transfer tokens back to user
        require(
            Token(_token).transfer(msg.sender, _amount),
            "Exchange: Token transfer failed"
        );
        
    }
    
    function totalBalanceOf(
        address _token,
        address _user
        ) public view returns (uint256) {
            return userTotalTokenBalance[_token] [_user];
        }

    function activeBalanceOf(
        address _token,
        address _user
        ) public view returns (uint256) {
            return userActiveTokenBalance[_token] [_user];
        }

    //_____________________________
    // Make and Cancel Orders

    function makeOrder(
        address _tokenGet,
        uint256 _amountGet,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
        address _tokenGive,
        uint256 _amountGive
    ) public {
        require(
            totalBalanceOf(_tokenGive, msg.sender) >=
            activeBalanceOf(_tokenGive,msg.sender) + _amountGive, 
            "Exchange: Insufficient balance"
        );

        // Update order count
        orderCount ++;
    
        // Instantiate a new order
        orders[orderCount] = Order(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            block.timestamp
        );

        //Update the user's active balance
        userActiveTokenBalance [_tokenGive] [msg.sender] += _amountGive;

        // emit Order Created (
        emit OrderCreated(
            orderCount,
            msg.sender,
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,    
            block.timestamp
        );
    }

    function cancelOrder(uint256 _id) public {
        // fetch the order
        Order storage order = orders[_id];

        // Order must exist
        require(order.id == _id, "Exchange: Order does not exist");

        // Ensure the caller of the function is the owner of the order
        require(address(order.user) == msg.sender, "Exchange: Not the order owner");

        // Cancel the order
        isOrderCancelled[_id] = true;

        // Update the active balance
        userActiveTokenBalance[order.tokenGive][order.user] -= order.amountGive;

        // Emit an event
        emit OrderCancelled(
            order.id,
            msg.sender,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            block.timestamp
        );
    }

        
}
