// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";

/// @title ILockToVetoPlugin
/// @author Aragon Association - 2022-2023
/// @notice The interface of an optimistic governance plugin.
interface ILockToVetoPlugin {
    /// @notice getter function for the voting token.
    /// @dev public function also useful for registering interfaceId and for distinguishing from majority voting interface.
    /// @return The token used for voting.
    function getVotingToken() external view returns (IERC20Upgradeable);

    /// @notice Returns the total voting power checkpointed for a specific block number.
    /// @return The total voting power.
    function totalVotingPower() external view returns (uint256);

    /// @notice Returns the veto ratio parameter stored in the optimistic governance settings.
    /// @return The veto ratio parameter.
    function minVetoRatio() external view returns (uint32);

    /// @notice Returns the minimum duration parameter stored in the vetoing settings.
    /// @return The minimum duration parameter.
    function minDuration() external view returns (uint64);

    /// @notice Returns the minimum vetoing power required to create a proposal stored in the vetoing settings.
    /// @return The minimum vetoing power required to create a proposal.
    function minProposerVotingPower() external view returns (uint256);

    /// @notice Creates a new optimistic proposal.
    /// @param _metadata The metadata of the proposal.
    /// @param _actions The actions that will be executed after the proposal passes.
    /// @param _allowFailureMap Allows proposal to succeed even if an action reverts. Uses bitmap representation. If the bit at index `x` is 1, the tx succeeds even if the action at `x` failed. Passing 0 will be treated as atomic execution.
    /// @param _startDate The start date of the proposal vote. If 0, the current timestamp is used and the vote starts immediately.
    /// @param _endDate The end date of the proposal vote. If 0, `_startDate + minDuration` is used.
    /// @return proposalId The ID of the proposal.
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate
    ) external returns (uint256 proposalId);

    /// @notice Checks if an account can participate on an optimistic proposal. This can be because the proposal
    /// - has not started,
    /// - has ended,
    /// - was executed, or
    /// - the voter doesn't have voting power.
    /// @param _proposalId The proposal Id.
    /// @param _account The account address to be checked.
    /// @return Returns true if the account is allowed to veto.
    /// @dev The function assumes that the queried proposal exists.
    function canVeto(
        uint256 _proposalId,
        address _account
    ) external view returns (bool);

    /// @notice Registers the veto for the given proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _amountToLock The amount the user wants to lock
    function veto(uint256 _proposalId, uint256 _amountToLock) external;

    /// @notice Returns whether the account has voted for the proposal.  Note, that this does not check if the account has vetoing power.
    /// @param _proposalId The ID of the proposal.
    /// @param _account The account address to be checked.
    /// @return The whether the given account has vetoed the given proposal.
    function hasVetoed(
        uint256 _proposalId,
        address _account
    ) external view returns (bool);

    /// @notice Returns whether the account has claimed their lock for the proposal.  Note, that this does not check if the account has vetoing power.
    /// @param _proposalId The ID of the proposal.
    /// @param _account The account address to be checked.
    /// @return The whether the given account has claimed their lock in the given proposal.
    function hasClaimedLock(
        uint256 _proposalId,
        address _account
    ) external view returns (bool);

    /// @notice Checks if the total votes against a proposal is greater than the veto threshold.
    /// @param _proposalId The ID of the proposal.
    /// @return Returns `true` if the total veto power against the proposal is greater or equal than the threshold and `false` otherwise.
    function isMinVetoRatioReached(
        uint256 _proposalId
    ) external view returns (bool);

    /// @notice Checks if a proposal can be executed.
    /// @param _proposalId The ID of the proposal to be checked.
    /// @return True if the proposal can be executed, false otherwise.
    function canExecute(uint256 _proposalId) external view returns (bool);

    /// @notice Executes a proposal.
    /// @param _proposalId The ID of the proposal to be executed.
    function execute(uint256 _proposalId) external;

    /// @notice Transfers back the amount a vetoer has locked
    /// @param _proposalId The ID of the proposal to claim
    /// @param _member The address of the person to claim their assets
    function claimLock(uint256 _proposalId, address _member) external;
}
