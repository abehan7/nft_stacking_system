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
    uint256 public constant STAKING_TIME_1 = 1 days;
    uint256 public constant STAKING_TIME_2 = 3 days;
    uint256 public constant STAKING_TIME_3 = 7 days;
    uint256 public constant STAKING_TIME_4 = 10 days;
    uint256 public constant STAKING_TIME_5 = 14 days;

    uint256 public totalStakingSupply = 0;

    uint256 public EMISSION_RATE = (50 * 10**decimals()) / 1 days; //하루에 50개 코인

    constructor(address _nftContract) ERC20("MyToken", "MTK") {
        nftContract = IERC721(_nftContract);
    }

    modifier onlyStakingTokenOwner(uint256 tokenId) {
        require(
            ownerOfStakingToken(tokenId) == msg.sender,
            "Only the owner of the staking token can do this"
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

    function ownerOfStakingToken(uint256 tokenId)
        public
        view
        returns (address)
    {
        return stakingTokenInfo[tokenId].owner;
    }

    function stake(uint256 tokenId, uint256 stakingTime)
        external
        onlyStakingTokenOwner(tokenId)
    {
        require(
            ownerOfStakingToken(tokenId) == address(0),
            "This token has already been staked"
        );
        //  require(
        //     tokenOwnerOf[tokenId] == address(0),
        //     "This token has already been staked"
        // );
        require(
            stakingTime == 1 ||
                stakingTime == 2 ||
                stakingTime == 3 ||
                stakingTime == 4,
            "Invalid staking time"
        );

        nftContract.approve(address(this), tokenId);
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        //
        // tokenOwnerOf[tokenId] = msg.sender;
        stakingTokenInfo[tokenId].owner = msg.sender;
        // tokenStakedAt[tokenId] = block.timestamp;
        stakingTokenInfo[tokenId].startTime = block.timestamp;

        // balance[msg.sender] += 1;
        userInfo[msg.sender].balance += 1;
        totalStakingSupply += 1;
        stakingTokenIds.push(tokenId);
    }

    function calculateTokens(uint256 tokenId) public view returns (uint256) {
        // uint256 timeElapsed = block.timestamp - tokenStakedAt[tokenId];
        uint256 timeElapsed = block.timestamp -
            stakingTokenInfo[tokenId].startTime;
        return timeElapsed * EMISSION_RATE;
    }

    function unstake(uint256 tokenId) external onlyStakingTokenOwner(tokenId) {
        _mint(msg.sender, calculateTokens(tokenId)); // Minting the tokens for staking
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        // delete tokenOwnerOf[tokenId];
        delete stakingTokenInfo[tokenId];
        // delete tokenStakedAt[tokenId];
        // balance[msg.sender] -= 1;
        userInfo[msg.sender].balance -= 1;
        totalStakingSupply -= 1;
        popToken(tokenId);
    }

    function claimTokens(uint256 tokenId)
        external
        onlyStakingTokenOwner(tokenId)
    {
        _mint(msg.sender, calculateTokens(tokenId)); // Minting the tokens for staking
        // tokenStakedAt[tokenId] = 0;
        stakingTokenInfo[tokenId].startTime = 0;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Invalid owner");
        // uint256[] memory tokens;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = stakingBalanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
            // 일단 여기서 오류날꺼 빼박이긴 한데 일단 돌려고보 없애자
            if (stakingTokenOwnerOf(i) != address(0)) {
                currOwnershipAddr = stakingTokenOwnerOf(i);
            }

            if (stakingTokenOwnerOf(i) == address(0)) {
                currOwnershipAddr = address(0);
            }

            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }

    function stakingBalanceOf(address account) public view returns (uint256) {
        return balance[account];
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
}
