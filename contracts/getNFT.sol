// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";

contract GetNFT {
    IERC721AQueryable public nftContract;

    constructor(address _nftContract) {
        nftContract = IERC721AQueryable(_nftContract);
    }

    struct TokenInfo {
        uint256 tokenId;
        address isApprovedAddress;
    }

    function getApprovedBatch(address _tokenOwner)
        public
        view
        returns (TokenInfo[] memory)
    {
        uint256[] memory tokenIds = nftContract.tokensOfOwner(_tokenOwner);
        uint256 tokenlength = tokenIds.length;
        TokenInfo[] memory _approvedTokens = new TokenInfo[](tokenlength);
        for (uint256 i = 0; i < tokenlength; i++) {
            _approvedTokens[i].isApprovedAddress = nftContract.getApproved(
                tokenIds[i]
            );
            _approvedTokens[i].tokenId = tokenIds[i];
        }
        return _approvedTokens;
    }
}
