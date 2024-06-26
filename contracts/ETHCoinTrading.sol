// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./IERC20.sol";

contract ETHCoinTrading {
    uint256 public tradesCounter;
    address payable public owner;
    address payable public feesAddress;
    uint256 public tradingfees;
    
    struct Trade {
        address payable seller;
        address payable buyer;
        uint256 tradeId;
        IERC20 token;
        uint256 tokenAmount;
        uint256 ethAmount;
        uint256 price;
        uint256 releaseTime;
        bool released;
        bool cancelTradeBySeller;
        bool cancelTradeByBuyer;
    }
    mapping(uint256 => Trade) public tradeDetails;
    event TokenTraded(
        address indexed trader,
        uint256 tokenAmount,
        uint256 tokenPrice
    );

    Trade[] public trades;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function.");
        _;
    }

    function setFeesAddress(address payable _feesAddress) public onlyOwner {
        feesAddress = _feesAddress;
    }

    function setTradingfees(uint256 _tradingfees) public onlyOwner {
        tradingfees = _tradingfees;
    }

    function listingFees() public payable {
        require(tradingfees > 0, "listingfees is more than zero");
        require(feesAddress != address(0), "address is not set");
        payable(feesAddress).transfer(tradingfees);
    }

    function tokenTrade(
        IERC20 _token,
        uint256 _tokenAmount,
        uint256 _tokenPrice,
        uint256 _releaseTime
    ) public payable {
        require(_tokenAmount > 0, "Token amount cannot be zero");
        require(_tokenPrice > 0, "Token price cannot be zero");
        require(msg.value == 0, "ETH cannot be sent for token trade");
        require(
            _token.balanceOf(msg.sender) >= _tokenAmount,
            "Insufficient token balance"
        );

        require(block.timestamp <= _releaseTime + 3 minutes, "Invaild Time");
        trades.push(
            Trade(
                payable(msg.sender),
                payable(address(0)),
                trades.length,
                _token,
                _tokenAmount,
                0,
                _tokenPrice,
                _releaseTime,
                false,
                false,
                false
            )
        );

        require(
            _token.transferFrom(msg.sender, address(this), _tokenAmount),
            "Token transfer failed"
        );
        emit TokenTraded(msg.sender, _tokenAmount, _tokenPrice);
    }

    function ethTrade(
        uint256 _ethAmount,
        uint256 _ethPrice,
        uint256 _releaseTime
    ) public payable {
        require(_ethPrice > 0, "ETH price cannot be zero");
        require(msg.value >= _ethAmount, "Incorrect ETH amount sent");
        require(
            block.timestamp <= _releaseTime + 3 minutes,
            "Invaild Time, atleast 3 minutes"
        );
        trades.push(
            Trade(
                payable(msg.sender),
                payable(address(0)),
                trades.length,
                IERC20(address(0)),
                0,
                _ethAmount,
                _ethPrice,
                _releaseTime,
                false,
                false,
                false
            )
        );
        tradesCounter++;
    }

    function buyToken(uint256 _tradeId) public payable {
        require(trades[_tradeId].released == false, "Already released.");

        require(
            trades[_tradeId].buyer == address(0),
            "This trade is already taken"
        );
        require(_tradeId < trades.length, "Invalid trade ID");
        require(
            trades[_tradeId].releaseTime > block.timestamp,
            "The trade is expired"
        );
        require(
            !trades[_tradeId].cancelTradeBySeller,
            "Trade is cancel by seller so we can't transfer funds"
        );
        uint256 totalPrice = trades[_tradeId].price;
        require(msg.value >= totalPrice, "Insufficient ETH sent");
        trades[_tradeId].buyer = payable(msg.sender);
    }

    function buyETH(uint256 _tradeId) public payable {
        require(trades[_tradeId].released == false, "Already release.");

        require(
            trades[_tradeId].buyer == address(0),
            "This trade is already taken"
        );
        require(_tradeId < trades.length, "Invalid trade ID");
        require(
            trades[_tradeId].releaseTime > block.timestamp,
            "The trade is expired"
        );
        require(
            !trades[_tradeId].cancelTradeBySeller,
            "Trade is cancel by seller so we can't transfer funds"
        );
        uint256 totalPrice = trades[_tradeId].price;
        require(totalPrice > 0, "Total price cannot be zero");
        require(msg.value <= totalPrice, "Insufficient ETH sent");
        trades[_tradeId].buyer = payable(msg.sender);
    }

    function release(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        require(
            msg.sender == trades[_tradeId].seller,
            "Unauthorized to release funds"
        );
        require(!trades[_tradeId].released, "Funds have already been released");
       
        require(
            !trades[_tradeId].cancelTradeBySeller,
            "Trade is cancel by seller so we can't transfer funds"
        );

        require(
            block.timestamp >= trades[_tradeId].releaseTime,
            "Release time not reached"
        );
        require(trades[_tradeId].buyer != address(0), "No buyer available for this trade then cancelTrade");
        if (trades[_tradeId].tokenAmount > 0) {
            payable(trades[_tradeId].seller).transfer(trades[_tradeId].price);
            trades[_tradeId].token.transfer(
                payable(trades[_tradeId].buyer),
                trades[_tradeId].tokenAmount
            );
        }

        if (trades[_tradeId].ethAmount > 0) {
            payable(trades[_tradeId].seller).transfer(trades[_tradeId].price);
            payable(trades[_tradeId].buyer).transfer(
                trades[_tradeId].ethAmount
            );
        }

        trades[_tradeId].released = true;
    }

    function claimByBuyer(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        require(
            msg.sender == trades[_tradeId].buyer,
            "Unauthorized to claim funds"
        );
        require(!trades[_tradeId].released, "Funds have already been released");
        require(
            block.timestamp >= trades[_tradeId].releaseTime,
            "Release time not reached"
        );
        if (trades[_tradeId].tokenAmount > 0) {
            trades[_tradeId].token.transfer(
                payable(trades[_tradeId].buyer),
                trades[_tradeId].tokenAmount
            );
        }

        if (trades[_tradeId].ethAmount > 0) {
            payable(trades[_tradeId].buyer).transfer(
                trades[_tradeId].ethAmount
            );
        }
    }

    function claimBySeller(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        require(
            msg.sender == trades[_tradeId].seller,
            "Unauthorized to claim funds"
        );
        require(!trades[_tradeId].released, "Funds have already been released");
        require(
            block.timestamp >= trades[_tradeId].releaseTime,
            "Release time not reached"
        );
        if (trades[_tradeId].tokenAmount > 0) {
            payable(trades[_tradeId].seller).transfer(trades[_tradeId].price);
        }

        if (trades[_tradeId].ethAmount > 0) {
            payable(trades[_tradeId].seller).transfer(trades[_tradeId].price);
        }
    }

    function cancelTradeBySeller(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        require(
            msg.sender == trades[_tradeId].seller,
            "Unauthorized to cancel Trade funds"
        );
        require(!trades[_tradeId].released, "Funds have already been released");

        if (trades[_tradeId].tokenAmount > 0) {
            trades[_tradeId].token.transfer(
                payable(trades[_tradeId].seller),
                trades[_tradeId].tokenAmount
            );
        }

        if (trades[_tradeId].ethAmount > 0) {
            payable(trades[_tradeId].seller).transfer(
                trades[_tradeId].ethAmount
            );
        }

        trades[_tradeId].cancelTradeBySeller = true;
         if (trades[_tradeId].buyer != payable(address(0))) {
            address payable buyerAddress = trades[_tradeId].buyer;
            uint256 price = trades[_tradeId].price;
            (buyerAddress).transfer(price);
        }
    }

    function cancelTradeByBuyer(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        require(
            msg.sender == trades[_tradeId].buyer,
            "Unauthorized to cancel Trade funds"
        );
        require(!trades[_tradeId].released, "Funds have already been released");

        if (trades[_tradeId].tokenAmount > 0) {
            payable(trades[_tradeId].buyer).transfer(trades[_tradeId].price);
        }

        if (trades[_tradeId].ethAmount > 0) {
            payable(trades[_tradeId].buyer).transfer(trades[_tradeId].price);
        }

        trades[_tradeId].cancelTradeByBuyer = true;
        trades[_tradeId].buyer = payable(address(0));
        
          trades.push(
            Trade(
                payable(trades[_tradeId].seller),
                payable(address(0)),
                trades.length,
                trades[_tradeId].token,
                trades[_tradeId].tokenAmount,
                trades[_tradeId].ethAmount,
                trades[_tradeId].price,
                trades[_tradeId].releaseTime,
                false,
                false,
                true
            )
        );
    }

    function withdrawToken(address token) external onlyOwner {
        require(feesAddress != address(0), "Wallet address is not set");
        ERC20 tokenInstance = ERC20(token);
        uint256 tokenBalance = tokenInstance.balanceOf(address(this));
        tokenInstance.transfer(feesAddress, tokenBalance);
    }

    function withdrawETH() external onlyOwner {
        require(feesAddress != address(0), "Wallet address is not set");
        uint256 ethbalance = address(this).balance;
        require(ethbalance > 0, "insufficient balance");
        feesAddress.transfer(ethbalance);
    }
}
