// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IStakeSystem
 * @author Abe
 * @dev StakeSystem interface.
 */

interface IStakeSystem {
    /**
     * @notice This struct contains data related to a Staked Tokens
     *
     * @param stackedTokenIds - Array of tokenIds that are staked
     * @param successedTokenIds - Array of tokenIds that are successfully staked
     * @param stakingTokenIds - Array of tokenIds that are staking
     */

    struct UserInfo {
        uint256[] stackedTokenIds;
        uint256 balance;
    }

    /**
     *
     * @param successedNum - Number of successfully staked tokens
     * @param owner - Owner of the token
     * @param isStacked - Whether the token are stacked
     * @param isWithdrawable - Whether the token are withdrawable
     * @param startTime - Start time of the staking
     * @param finishingTime - Finishing time of the staking
     */

    struct StakingTokenInfo {
        address owner;
        bool isStacked;
        uint256 startTime;
        uint256 finishingTime;
    }
}
