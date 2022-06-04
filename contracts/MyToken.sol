// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MyToken is ERC20, ERC721Holder, Ownable {
    IERC721 public nft;

    mapping(uint256 => address) public tokenOwnerOf;
    mapping(uint256 => uint256) public tokenStakedAt;
    mapping(address => uint256) internal balance;
    uint256[] public stakingTokenIds;

    // mapping(address => uint256) internal stakedBalance;
    // mapping(uint256 => bool) internal staked;
    uint256 public totalStakingSupply = 0;

    uint256 public EMISSION_RATE = (50 * 10**decimals()) / 1 days;

    constructor(address _nft) ERC20("MyToken", "MTK") {
        nft = IERC721(_nft);
    }

    function popToken(uint256 _tokenId) private {
        for (uint256 i = 0; i < stakingTokenIds.length; i++) {
            if (stakingTokenIds[i] == _tokenId) {
                stakingTokenIds[i] = stakingTokenIds[
                    stakingTokenIds.length - 1
                ];
                stakingTokenIds.pop();
            }
        }
    }

    function stake(uint256 tokenId) external {
        require(
            tokenOwnerOf[tokenId] == address(0),
            "This token has already been staked"
        );
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        tokenOwnerOf[tokenId] = msg.sender;
        tokenStakedAt[tokenId] = block.timestamp;
        balance[msg.sender] += 1;
        totalStakingSupply += 1;
        stakingTokenIds.push(tokenId);
    }

    function calculateTokens(uint256 tokenId) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - tokenStakedAt[tokenId];
        return timeElapsed * EMISSION_RATE;
    }

    function unstake(uint256 tokenId) external {
        require(tokenOwnerOf[tokenId] == msg.sender, "You can't unstake");
        _mint(msg.sender, calculateTokens(tokenId)); // Minting the tokens for staking
        nft.transferFrom(address(this), msg.sender, tokenId);
        delete tokenOwnerOf[tokenId];
        delete tokenStakedAt[tokenId];
        balance[msg.sender] -= 1;
        totalStakingSupply -= 1;
        popToken(tokenId);
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
            if (tokenOwnerOf[i] != address(0)) {
                currOwnershipAddr = tokenOwnerOf[i];
            }

            if (tokenOwnerOf[i] == address(0)) {
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
            if (tokenOwnerOf[stakingTokenIds[i]] != address(0)) {
                tokenIds[tokenIdsIdx++] = stakingTokenIds[i];
            }
        }
        return tokenIds;
    }
}
