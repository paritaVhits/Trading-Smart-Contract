// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Coin.sol";
import "./NFT.sol";
import "./SafeMath.sol";


contract StakeNFT {
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    using SafeMath for uint256;
    Coin rewardtoken;
    NFT nft;
    address payable public owner;
    uint256 public listingfees;
    address public feesAddress;

    struct staker {
        address stakerAddress;
        IERC721 nftContract;
        uint256 tokenId;
        uint256 createdDate;
        uint256 unlockDate;
        bool release;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
        bool rewardsRelease;
        bool emergencyRelease;
    }

    staker[] public stakes;
    mapping(address => mapping(uint256 => staker)) public stakerDetails;

    mapping(uint256 => uint256) public tiers;
    uint256[] public lockPeriods;

    constructor(address payable _rewardtoken) {
        rewardtoken = Coin(_rewardtoken);
        owner = payable(msg.sender);

        tiers[30] = 7;
        tiers[90] = 10;
        tiers[180] = 12;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function.");
        _;
    }

    function setListingfees(uint256 _listingfees) public onlyOwner {
        listingfees = _listingfees;
    }

    function setFeesAddress(address payable _feesAddress) public onlyOwner {
        feesAddress = _feesAddress;
    }

    function stakeNFTs(
        IERC721 _nftContract,
        uint256 _tokenId,
        uint256 _numDays
    ) public payable {
        require(
            _nftContract.ownerOf(_tokenId) == msg.sender,
            "this is not a NFT Owner"
        );
        require(_tokenId > 0, "tokenId is greater than zero");
        require(tiers[_numDays] > 0, "Mapping not Found");

        staker memory Stakers = staker(
            payable(msg.sender),
            _nftContract,
            _tokenId,
            block.timestamp,
            block.timestamp + (_numDays * 1 days),
            false,
            0,
            0,
            false,
            false
        );

        stakes.push(
            staker(
                payable(msg.sender),
                _nftContract,
                _tokenId,
                block.timestamp,
                block.timestamp + (_numDays * 1 days),
                false,
                0,
                0,
                false,
                false
            )
        );
        stakerDetails[msg.sender][_tokenId] = Stakers;
        _nftContract.transferFrom(msg.sender, address(this), _tokenId);
    }

    function getLockperiods() external view returns (uint256[] memory) {
        return lockPeriods;
    }

    function stakeMultiple(
        IERC721 _nftContract,
        uint256[] memory _tokenIds,
        uint256 _numDays
    ) public payable {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 id = _tokenIds[i];
            require(
                _nftContract.ownerOf(id) == msg.sender,
                "this is not a NFT Owner"
            );
            require(id > 0, "tokenId is greater than zero");
            require(tiers[_numDays] > 0, "Mapping not Found");

            staker memory Stakers = staker(
                payable(msg.sender),
                _nftContract,
                id,
                block.timestamp,
                block.timestamp + (_numDays * 1 days),
                false,
                0,
                0,
                false,
                false
            );

            stakes.push(
                staker(
                    payable(msg.sender),
                    _nftContract,
                    id,
                    block.timestamp,
                    block.timestamp + (_numDays * 1 days),
                    false,
                    0,
                    0,
                    false,
                    false
                )
            );
            stakerDetails[msg.sender][id] = Stakers;
            _nftContract.transferFrom(msg.sender, address(this), id);
        }
    }

    function listingFeesforMultiple() public payable {
        require(listingfees > 0, "listingfees is more than zero");
        require(feesAddress != address(0), "address is not set");
        payable(feesAddress).transfer(listingfees * 1 ether);
    }

    function unStake(uint256 _tokenId) public payable {
        staker storage newunStaker = stakerDetails[msg.sender][_tokenId];
        require(newunStaker.stakerAddress == msg.sender, "No NFT staked");
        require(block.timestamp > newunStaker.unlockDate, "no unstake time");
        require(newunStaker.tokenId == _tokenId, "No NFT Id Staked");
        require(
            rewardtoken.balanceOf(address(this)) > 0,
            "reward amount is not sufficient"
        );
        uint256 rewardsEarned = newunStaker.unlockDate *
            tiers[newunStaker.unlockDate];

        newunStaker.rewardsEarned += rewardsEarned;
        newunStaker.release = true;

        newunStaker.nftContract.transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    function claimReward(uint256 _tokenId) public payable {
        staker storage newstakeReward = stakerDetails[msg.sender][_tokenId];
        require(newstakeReward.stakerAddress == msg.sender, "No NFT staked");
        require(newstakeReward.tokenId == _tokenId, "No NFT Id Staked");
        require(
            !newstakeReward.rewardsRelease,
            "Funds have already been released"
        );
        rewardtoken.transfer(payable(msg.sender), newstakeReward.rewardsEarned);
        newstakeReward.rewardsRelease = true;
        newstakeReward.rewardsReleased = newstakeReward.rewardsReleased.add(
            newstakeReward.rewardsEarned
        );
        newstakeReward.rewardsEarned = newstakeReward.rewardsReleased.sub(
            newstakeReward.rewardsReleased
        );
    }

    function emergencyUnstake(uint256 _tokenId) public {
        staker storage newunStaker = stakerDetails[msg.sender][_tokenId];
        require(newunStaker.stakerAddress == msg.sender, "No NFT staked");
        require(newunStaker.tokenId == _tokenId, "No NFT Id Staked");
        newunStaker.nftContract.transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        newunStaker.emergencyRelease = true;
    }

    function withdrawFunds() external onlyOwner {
        require(feesAddress != address(0), "Wallet address is not set");
        uint256 ethbalance = address(this).balance;
        require(ethbalance > 0, "insufficient balance");
        payable(feesAddress).transfer(ethbalance);

        ERC20 tokenInstance = ERC20(rewardtoken);
        uint256 tokenBalance = tokenInstance.balanceOf(address(this));
        tokenInstance.transfer(feesAddress, tokenBalance);
    }

    function fetchStakeItems() public view returns (staker[] memory) {
        uint256 currentIndex = 0;

        staker[] memory unsoldItems = new staker[](stakes.length);

        for (uint256 i = 0; i < stakes.length; i++) {
            if (!stakes[i].release) {
                unsoldItems[currentIndex] = stakes[i];
                currentIndex++;
            }
        }

        return unsoldItems;
    }

    function getActiveStake() external view returns (staker[] memory) {
        uint256 activestakeCount = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].unlockDate > block.timestamp) {
                activestakeCount++;
            }
        }

        staker[] memory activeTrades = new staker[](activestakeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].unlockDate > block.timestamp) {
                activeTrades[currentIndex] = stakes[i];
                currentIndex++;
            }
        }

        return activeTrades;
    }

    function getMyStake(address user) external view returns (staker[] memory) {
        uint256 stakeCount = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakerAddress == user) {
                stakeCount++;
            }
        }

        staker[] memory myTrades = new staker[](stakeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].stakerAddress == user) {
                myTrades[currentIndex] = stakes[i];
                currentIndex++;
            }
        }
        return myTrades;
    }
}
