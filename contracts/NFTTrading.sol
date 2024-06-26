pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Counters.sol";

contract NFTTrading {
    uint256 public tradingCounter;
    address payable public owner;
    address payable public feesAddress;
    uint256 public tradingfees;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    struct TradeNFT {
        address payable seller;
        address payable buyer;
        address payable owner;
        IERC721 nftContract;
        uint256 tokenId;
        uint256 tradeId;
        uint256 price;
        uint256 releaseTime;
        bool releaseNFT;
        bool releaseFund;
        bool cancelTradeBySeller;
        bool cancelTradeByBuyer;
        // bool active;
    }

    TradeNFT[] public trades;

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

    function tradeNFT(
        IERC721 _nftContract,
        uint256 _tokenId,
        uint256 _releaseTime,
        uint256 _price
    ) public payable {
        require(_price > 0, "Invaild Price");
        require(block.timestamp < _releaseTime + 5 minutes, "Invaild Time");

        trades.push(
            TradeNFT(
                payable(msg.sender),
                payable(address(0)),
                payable(address(this)),
                _nftContract,
                _tokenId,
                trades.length,
                _price,
                _releaseTime,
                false,
                false,
                false,
                false
                // true
            )
        );

        _nftContract.transferFrom(msg.sender, address(this), _tokenId);
        tradingCounter++;
    }

    function buyNFT(uint256 _tradeId) public payable {
        require(_tradeId < trades.length, "Invalid trade ID");
        TradeNFT storage trade = trades[_tradeId];
        require(trade.buyer == address(0), "This trade is already taken");
        require(block.timestamp <= trade.releaseTime, "The trade is expired");
        require(
            !trade.cancelTradeBySeller,
            "Trade is canceled by seller so we can't transfer funds"
        );
        uint256 totalPrice = trade.price;
        require(msg.value >= totalPrice, "Insufficient ETH sent");

        trade.buyer = payable(msg.sender);
    }

    function releaseNFT(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        TradeNFT storage trade = trades[_tradeId];
        require(msg.sender == trade.seller, "Unauthorized to release funds");
        require(!trade.releaseNFT, "Funds have already been released");

        require(trade.buyer != address(0), "No buyer yet");
        require(
            block.timestamp >= trade.releaseTime,
            "Release time not reached"
        );

        trade.nftContract.transferFrom(
            address(this),
            (trade.buyer),
            trade.tokenId
        );

        trade.releaseNFT = true;
    }

    function releaseFunds(uint256 _tradeId) public {
        TradeNFT storage trade = trades[_tradeId];
        require(msg.sender == trade.seller, "Unauthorized to claim funds");
        require(!trade.releaseFund, "Funds have already been released");
        require(trade.buyer != address(0), "No buyer yet");
        require(
            block.timestamp >= trade.releaseTime,
            "Release time not reached"
        );
        address payable sellerAdress = trade.seller;
        uint256 price = trade.price;
        (sellerAdress).transfer(price);

        trade.releaseFund = true;
    }

    function claimNFTbyUser(uint256 _tradeId) public {
        TradeNFT storage trade = trades[_tradeId];
        require(msg.sender == trade.buyer, "Unauthorized to claim NFT");
        require(!trade.releaseNFT, "NFT has already been released");
        require(
            block.timestamp >= trade.releaseTime,
            "Release time not reached"
        );
        require(
            !trade.cancelTradeByBuyer,
            "Trade is cancel by Buyer so we can't transfer funds"
        );
        trade.nftContract.transferFrom(
            address(this),
            (trade.buyer),
            trade.tokenId
        );

        trade.releaseNFT = true;
    }

    function withdrawFunds() external onlyOwner {
        require(feesAddress != address(0), "Wallet address is not set");
        uint256 ethbalance = address(this).balance;
        require(ethbalance > 0, "insufficient balance");
        payable(feesAddress).transfer(ethbalance);
    }

    function cancelTradeBySeller(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        TradeNFT storage trade = trades[_tradeId];
        require(
            msg.sender == trade.seller,
            "Unauthorized to cancel Trade funds"
        );
        require(!trade.releaseNFT, "Funds have already been released");
        require(
            block.timestamp <= trade.releaseTime,
            "Release time already Reched"
        );
        trade.nftContract.transferFrom(
            address(this),
            (trade.seller),
            trade.tokenId
        );
        trade.cancelTradeBySeller = true;
        if (trade.buyer != payable(address(0))) {
            address payable buyerAddress = trade.buyer;
            uint256 price = trade.price;
            (buyerAddress).transfer(price);
        }
    }

    function cancelTradeByBuyer(uint256 _tradeId) public {
        require(_tradeId < trades.length, "Invalid Trade ID");
        TradeNFT storage trade = trades[_tradeId];
        require(!trade.releaseFund, "Funds have already been released");
        require(
            block.timestamp <= trade.releaseTime,
            "Release time already Reched"
        );
        address payable buyerAddress = trade.buyer;
        uint256 price = trade.price;
        (buyerAddress).transfer(price);
        trade.cancelTradeByBuyer = true;
        trade.buyer = payable(address(0));
        trades[_tradeId].buyer = payable(address(0));
    }

    function getNFTDetails(uint256 tokenId)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        TradeNFT storage trade = trades[tokenId -1];
        return (
            address(trade.nftContract),
            trade.tokenId,
            trade.price,
            trade.tradeId,
            trade.releaseTime
        );
    }

    function fetchMarketItems() public view returns (TradeNFT[] memory) {
        uint256 currentIndex = 0;

        TradeNFT[] memory unsoldItems = new TradeNFT[](trades.length);

        for (uint256 i = 0; i < trades.length; i++) {
            if (!trades[i].releaseNFT && !trades[i].cancelTradeBySeller) {
                unsoldItems[currentIndex] = trades[i];
                currentIndex++;
            }
        }

        return unsoldItems;
    }

    function fetchMyNFTs() public view returns (TradeNFT[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].buyer == msg.sender && trades[i].releaseNFT) {
                itemCount += 1;
            }
        }

        TradeNFT[] memory myItems = new TradeNFT[](itemCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].buyer == msg.sender && trades[i].releaseNFT) {
                myItems[currentIndex] = trades[i];
                currentIndex += 1;
            }
        }

        return myItems;
    }

    function getMyTrades(address user)
        external
        view
        returns (TradeNFT[] memory)
    {
        uint256 tradeCount = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].seller == user || trades[i].buyer == user) {
                tradeCount++;
            }
        }

        TradeNFT[] memory myTrades = new TradeNFT[](tradeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].seller == user || trades[i].buyer == user) {
                myTrades[currentIndex] = trades[i];
                currentIndex++;
            }
        }

        return myTrades;
    }

    function getActiveTrades() external view returns (TradeNFT[] memory) {
        uint256 activeTradeCount = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].releaseTime > block.timestamp) {
                activeTradeCount++;
            }
        }

        TradeNFT[] memory activeTrades = new TradeNFT[](activeTradeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].releaseTime > block.timestamp) {
                activeTrades[currentIndex] = trades[i];
                currentIndex++;
            }
        }

        return activeTrades;
    }

    receive() external payable {}
}
