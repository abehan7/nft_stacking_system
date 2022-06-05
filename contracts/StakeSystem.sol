// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IStakeSystem.sol";

contract StakeSystem is ERC20, ERC721Holder, Ownable {
    IERC721 public nftContract;

    mapping(uint256 => uint256) public tokenStakedAt;

    mapping(address => uint256) internal balance;
    mapping(address => IStakeSystem.UserInfo) internal userInfo;
    mapping(uint256 => IStakeSystem.StakingTokenInfo) internal stakingTokenInfo;

    function stakingTokenOwnerOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        return stakingTokenInfo[tokenId].owner;
    }

    uint256[] public stakingTokenIds;

    uint256[] STAKING_TIME_ARR = [1 days, 3 days, 7 days, 10 days, 14 days];

    uint256 public totalStakingSupply = 0;

    uint256 public EMISSION_RATE = (50 * 10**decimals()) / 1 days; //하루에 50개 코인

    constructor(address _nftContract) ERC20("MyToken", "MTK") {
        nftContract = IERC721(_nftContract);
    }

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 tokenId);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 tokenId);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "Only the token owner can do this"
        );
        _;
    }

    modifier isValidStakingTime(uint256 stakingTime) {
        require(
            stakingTime == 0 ||
                stakingTime == 1 ||
                stakingTime == 2 ||
                stakingTime == 3 ||
                stakingTime == 4,
            "Invalid staking time"
        );
        _;
    }

    function popToken(uint256 _tokenId) internal {
        for (uint256 i = 0; i < stakingTokenIds.length; i++) {
            if (stakingTokenIds[i] == _tokenId) {
                stakingTokenIds[i] = stakingTokenIds[
                    stakingTokenIds.length - 1
                ];
                stakingTokenIds.pop();
            }
        }
    }

    function isWithdrawable(uint256 _tokenId) public view returns (bool) {
        return stakingTokenInfo[_tokenId].finishingTime >= block.timestamp;
    }

    function ownerOfStakingToken(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return stakingTokenInfo[_tokenId].owner;
    }

    function stake(uint256 _tokenId, uint256 stakingTime)
        external
        isValidStakingTime(stakingTime)
    {
        require(
            ownerOfStakingToken(_tokenId) == address(0),
            "This token has already been staked"
        );

        // nft.approve(address(this), _tokenId);
        // approve는 여기서 하는거 아니고 원래 nft만든 contract에서 해줘야 하는거야
        // 여기서 safeTransferfrom은 자동으로 approve됐는지 확인해주는 기능이 있어
        // 이거가 자동으로 블락킹해
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        stakingTokenInfo[_tokenId].owner = msg.sender;
        stakingTokenInfo[_tokenId].startTime = block.timestamp;
        stakingTokenInfo[_tokenId].isStacked = true;
        stakingTokenInfo[_tokenId].finishingTime =
            block.timestamp +
            STAKING_TIME_ARR[stakingTime];
        userInfo[msg.sender].balance += 1;
        totalStakingSupply += 1;
        stakingTokenIds.push(_tokenId);
        emit Staked(msg.sender, _tokenId);
    }

    function calculateTokens(uint256 _tokenId) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp -
            stakingTokenInfo[_tokenId].startTime;
        return timeElapsed * EMISSION_RATE;
    }

    function unstake(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        // checkout if the token staked or not
        require(
            stakingTokenInfo[_tokenId].isStacked,
            "This token is not staked"
        );
        _mint(msg.sender, calculateTokens(_tokenId)); // Minting the tokens for staking
        nftContract.transferFrom(address(this), msg.sender, _tokenId);
        delete stakingTokenInfo[_tokenId];
        userInfo[msg.sender].balance -= 1;
        totalStakingSupply -= 1;
        popToken(_tokenId);
        emit Unstaked(msg.sender, _tokenId);
    }

    function giveUpStaking(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
        require(!isWithdrawable(_tokenId), "This token is withdrawable");
        nftContract.transferFrom(address(this), msg.sender, _tokenId);
        delete stakingTokenInfo[_tokenId];
        userInfo[msg.sender].balance -= 1;
        totalStakingSupply -= 1;
        popToken(_tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    function claimTokens(uint256 _tokenId, uint256 stakingTime)
        external
        onlyTokenOwner(_tokenId)
        isValidStakingTime(stakingTime)
    {
        require(isWithdrawable(_tokenId), "The token is not withdrawable");
        _mint(msg.sender, calculateTokens(_tokenId)); // Minting the tokens for staking
        stakingTokenInfo[_tokenId].startTime = block.timestamp;
        // uint256[] STAKING_TIME_ARR = [1 days, 3 days, 7 days, 10 days, 14 days];
        stakingTokenInfo[_tokenId].finishingTime = STAKING_TIME_ARR[
            stakingTime
        ];
        emit RewardPaid(msg.sender, calculateTokens(_tokenId));
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        require(_owner != address(0), "Invalid owner");
        // uint256[] memory tokens;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = stakingBalanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
            // 일단 여기서 오류날꺼 빼박이긴 한데 일단 돌려고보 없애자
            if (stakingTokenOwnerOf(i) != address(0)) {
                currOwnershipAddr = stakingTokenOwnerOf(i);
            }

            if (stakingTokenOwnerOf(i) == address(0)) {
                currOwnershipAddr = address(0);
            }

            if (currOwnershipAddr == _owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }

    function stakingBalanceOf(address _owner) public view returns (uint256) {
        return userInfo[_owner].balance;
        // return balance[account];
    }

    function getTotalStakingTokenIds() public view returns (uint256[] memory) {
        uint256 tokenIdsLength = stakingTokenIds.length;
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        uint256 tokenIdsIdx = 0;
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            if (stakingTokenOwnerOf(stakingTokenIds[i]) != address(0)) {
                tokenIds[tokenIdsIdx++] = stakingTokenIds[i];
            }
        }
        return tokenIds;
    }

    function getStakingTokenTimes(uint256 tokenId)
        public
        view
        returns (uint256[2] memory)
    {
        return [
            stakingTokenInfo[tokenId].startTime,
            stakingTokenInfo[tokenId].finishingTime
        ];
    }
}
