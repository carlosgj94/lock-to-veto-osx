// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console2} from "forge-std/Test.sol";
import {LockToVetoPlugin} from "../src/LockToVetoPlugin.sol";
import {LockToVetoPluginSetup} from "../src/LockToVetoPluginSetup.sol";
import {GovernanceERC20} from "@aragon/osx/token/ERC20/governance/GovernanceERC20.sol";
import {GovernanceWrappedERC20} from "@aragon/osx/token/ERC20/governance/GovernanceWrappedERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {RATIO_BASE} from "@aragon/osx/plugins/utils/Ratio.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

contract LockToVetoPluginSetupTest is Test {
    LockToVetoPluginSetup public pluginSetup;
    GovernanceERC20 governanceERC20Base;
    GovernanceWrappedERC20 governanceWrappedERC20Base;
    address immutable daoBase = address(new DAO());
    DAO dao;

    // Recycled installation parameters
    LockToVetoPlugin.OptimisticGovernanceSettings votingSettings;
    LockToVetoPluginSetup.TokenSettings tokenSettings;
    GovernanceERC20.MintSettings mintSettings;

    address alice = address(0xa11ce);

    error Unimplemented();

    function setUp() public {
        if (address(governanceERC20Base) == address(0x0)) {
            // Base
            GovernanceERC20.MintSettings memory _mintSettings = GovernanceERC20
                .MintSettings(new address[](0), new uint256[](0));
            governanceERC20Base = new GovernanceERC20(
                IDAO(address(0x0)),
                "",
                "",
                _mintSettings
            );
            // Base
            governanceWrappedERC20Base = new GovernanceWrappedERC20(
                IERC20Upgradeable(address(0x0)),
                "",
                ""
            );
            dao = DAO(
                payable(
                    createProxyAndCall(
                        address(daoBase),
                        abi.encodeWithSelector(
                            DAO.initialize.selector,
                            "",
                            alice,
                            address(0x0),
                            ""
                        )
                    )
                )
            );
        }

        pluginSetup = new LockToVetoPluginSetup(
            governanceERC20Base,
            governanceWrappedERC20Base
        );

        // Default params
        votingSettings = LockToVetoPlugin.OptimisticGovernanceSettings({
            minVetoRatio: uint32(RATIO_BASE / 10),
            minDuration: 5 days,
            minProposerVotingPower: 0
        });
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(governanceERC20Base),
            name: "Wrapped Token",
            symbol: "wTK"
        });
        mintSettings = GovernanceERC20.MintSettings({
            receivers: new address[](0),
            amounts: new uint256[](0)
        });
    }

    function test_ShouldEncodeInstallationParams_Default() public {
        // Default
        bytes memory output = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );

        bytes
            memory expected = hex"00000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000000000000069780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002200000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000d5772617070656420546f6b656e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000377544b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000001234567890";
        assertEq(output, expected, "Incorrect encoded bytes");
    }

    function test_ShouldEncodeInstallationParams_1() public {
        // Custom 1
        votingSettings = LockToVetoPlugin.OptimisticGovernanceSettings({
            minVetoRatio: uint32(RATIO_BASE / 5),
            minDuration: 60 * 60 * 24 * 5,
            minProposerVotingPower: 123456
        });
        bytes memory output = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );

        bytes
            memory expected = hex"0000000000000000000000000000000000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000069780000000000000000000000000000000000000000000000000000000000001e24000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002200000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000d5772617070656420546f6b656e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000377544b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000001234567890";
        assertEq(output, expected, "Incorrect encoded bytes");
    }

    function test_ShouldEncodeInstallationParams_2() public {
        // Custom 2
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(0x5678),
            name: "Wrapped New Coin",
            symbol: "wNCN"
        });
        bytes memory output = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );

        bytes
            memory expected = hex"00000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000000000000069780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000005678000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000001057726170706564204e657720436f696e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004774e434e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000001234567890";
        assertEq(output, expected, "Incorrect encoded bytes");
    }

    function test_ShouldEncodeInstallationParams_3() public {
        // Custom 3
        address[] memory receivers = new address[](1);
        receivers[0] = address(0x6789);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1234567890;

        mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,
            amounts: amounts
        });
        bytes memory output = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );

        bytes
            memory expected = hex"00000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000000000000069780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002600000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000d5772617070656420546f6b656e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000377544b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000006789000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000499602d200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000001234567890";
        assertEq(output, expected, "Incorrect encoded bytes");
    }

    function test_ShouldEncodeInstallationParams_4() public {
        // Custom 4

        bytes memory output = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );

        bytes
            memory expected = hex"00000000000000000000000000000000000000000000000000000000000186a00000000000000000000000000000000000000000000000000000000000069780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000002200000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000d5772617070656420546f6b656e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000377544b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000567890";
        assertEq(output, expected, "Incorrect encoded bytes");
    }

    function test_ShouldDecodeInstallationParams() public {
        votingSettings = LockToVetoPlugin.OptimisticGovernanceSettings({
            minVetoRatio: uint32(RATIO_BASE / 4),
            minDuration: 10 days,
            minProposerVotingPower: 55555555
        });
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(governanceWrappedERC20Base),
            name: "Super wToken",
            symbol: "SwTK"
        });
        address[] memory receivers = new address[](2);
        receivers[0] = address(0x1234);
        receivers[1] = address(0x5678);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2000;
        amounts[1] = 5000;
        mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,
            amounts: amounts
        });
        bytes memory _installationParams = pluginSetup.encodeInstallationParams(
                votingSettings,
                tokenSettings,
                // only used for GovernanceERC20 (when a token is not passed)
                mintSettings
            );

        // Decode
        (
            LockToVetoPlugin.OptimisticGovernanceSettings
                memory _votingSettings,
            LockToVetoPluginSetup.TokenSettings memory _tokenSettings,
            GovernanceERC20.MintSettings memory _mintSettings
        ) = pluginSetup.decodeInstallationParams(_installationParams);

        // Voting
        assertEq(
            _votingSettings.minVetoRatio,
            uint32(RATIO_BASE / 4),
            "Incorrect ratio"
        );
        assertEq(
            _votingSettings.minDuration,
            10 days,
            "Incorrect min duration"
        );
        assertEq(
            _votingSettings.minProposerVotingPower,
            55555555,
            "Incorrect min voting power"
        );

        // Token
        assertEq(
            _tokenSettings.addr,
            address(governanceWrappedERC20Base),
            "Incorrect token address"
        );
        assertEq(
            _tokenSettings.name,
            "Super wToken",
            "Incorrect token address"
        );
        assertEq(_tokenSettings.symbol, "SwTK", "Incorrect token address");

        // Mint
        assertEq(
            _mintSettings.receivers.length,
            2,
            "Incorrect receivers.length"
        );
        assertEq(
            _mintSettings.receivers[0],
            address(0x1234),
            "Incorrect receivers[0]"
        );
        assertEq(
            _mintSettings.receivers[1],
            address(0x5678),
            "Incorrect receivers[1]"
        );
        assertEq(_mintSettings.amounts.length, 2, "Incorrect amounts.length");
        assertEq(_mintSettings.amounts[0], 2000, "Incorrect amounts[0]");
        assertEq(_mintSettings.amounts[1], 5000, "Incorrect amounts[1]");
    }

    function test_PrepareInstallationReturnsTheProperPermissions_Default()
        public
    {
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            // only used for GovernanceERC20 (when a token is not passed)
            mintSettings
        );

        (
            address _plugin,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        assertEq(
            _plugin != address(0),
            true,
            "Plugin address should not be zero"
        );
        assertEq(_preparedSetupData.helpers.length, 1, "One helper expected");
        assertEq(
            _preparedSetupData.permissions.length,
            3, // base
            "Incorrect permission length"
        );
        // 1
        assertEq(
            uint256(_preparedSetupData.permissions[0].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[0].where, _plugin);
        assertEq(_preparedSetupData.permissions[0].who, address(dao));
        assertEq(_preparedSetupData.permissions[0].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[0].permissionId,
            keccak256("UPDATE_OPTIMISTIC_GOVERNANCE_SETTINGS_PERMISSION")
        );
        // 2
        assertEq(
            uint256(_preparedSetupData.permissions[1].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[1].where, _plugin);
        assertEq(_preparedSetupData.permissions[1].who, address(dao));
        assertEq(_preparedSetupData.permissions[1].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[1].permissionId,
            keccak256("UPGRADE_PLUGIN_PERMISSION")
        );
        // 3
        assertEq(
            uint256(_preparedSetupData.permissions[2].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[2].where, address(dao));
        assertEq(_preparedSetupData.permissions[2].who, _plugin);
        assertEq(_preparedSetupData.permissions[2].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[2].permissionId,
            keccak256("EXECUTE_PERMISSION")
        );
        // proposer 1
        assertEq(
            uint256(_preparedSetupData.permissions[3].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
    }

    function test_PrepareInstallationReturnsTheProperPermissions_UseToken()
        public
    {
        votingSettings = LockToVetoPlugin.OptimisticGovernanceSettings({
            minVetoRatio: uint32(RATIO_BASE / 4),
            minDuration: 10 days,
            minProposerVotingPower: 0
        });
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(governanceWrappedERC20Base),
            name: "",
            symbol: ""
        });

        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            // only used for GovernanceERC20 (when a token is not passed)
            mintSettings
        );

        (
            address _plugin,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        assertEq(
            _plugin != address(0),
            true,
            "Plugin address should not be zero"
        );
        assertEq(_preparedSetupData.helpers.length, 1, "One helper expected");
        assertEq(
            _preparedSetupData.permissions.length,
            3, // base
            "Incorrect permission length"
        );
        // 1
        assertEq(
            uint256(_preparedSetupData.permissions[0].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[0].where, _plugin);
        assertEq(_preparedSetupData.permissions[0].who, address(dao));
        assertEq(_preparedSetupData.permissions[0].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[0].permissionId,
            keccak256("UPDATE_OPTIMISTIC_GOVERNANCE_SETTINGS_PERMISSION")
        );
        // 2
        assertEq(
            uint256(_preparedSetupData.permissions[1].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[1].where, _plugin);
        assertEq(_preparedSetupData.permissions[1].who, address(dao));
        assertEq(_preparedSetupData.permissions[1].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[1].permissionId,
            keccak256("UPGRADE_PLUGIN_PERMISSION")
        );
        // 3
        assertEq(
            uint256(_preparedSetupData.permissions[2].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[2].where, address(dao));
        assertEq(_preparedSetupData.permissions[2].who, _plugin);
        assertEq(_preparedSetupData.permissions[2].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[2].permissionId,
            keccak256("EXECUTE_PERMISSION")
        );
        // proposer 1
        assertEq(
            uint256(_preparedSetupData.permissions[3].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
    }

    function test_PrepareInstallationReturnsTheProperPermissions_MintToken()
        public
    {
        votingSettings = LockToVetoPlugin.OptimisticGovernanceSettings({
            minVetoRatio: uint32(RATIO_BASE / 4),
            minDuration: 10 days,
            minProposerVotingPower: 4000
        });
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(0x0),
            name: "Wrapped Super New Token",
            symbol: "wSNTK"
        });
        address[] memory receivers = new address[](2);
        receivers[0] = address(0x1234);
        receivers[1] = address(0x5678);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2000;
        amounts[1] = 5000;
        mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,
            amounts: amounts
        });
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            // only used for GovernanceERC20 (when a token is not passed)
            mintSettings
        );

        (
            address _plugin,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        assertEq(
            _plugin != address(0),
            true,
            "Plugin address should not be zero"
        );
        assertEq(_preparedSetupData.helpers.length, 1, "One helper expected");
        assertEq(
            _preparedSetupData.permissions.length,
            3, // base
            "Incorrect permission length"
        );
        // 1
        assertEq(
            uint256(_preparedSetupData.permissions[0].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[0].where, _plugin);
        assertEq(_preparedSetupData.permissions[0].who, address(dao));
        assertEq(_preparedSetupData.permissions[0].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[0].permissionId,
            keccak256("UPDATE_OPTIMISTIC_GOVERNANCE_SETTINGS_PERMISSION")
        );
        // 2
        assertEq(
            uint256(_preparedSetupData.permissions[1].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[1].where, _plugin);
        assertEq(_preparedSetupData.permissions[1].who, address(dao));
        assertEq(_preparedSetupData.permissions[1].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[1].permissionId,
            keccak256("UPGRADE_PLUGIN_PERMISSION")
        );
        // 3
        assertEq(
            uint256(_preparedSetupData.permissions[2].operation),
            uint256(PermissionLib.Operation.Grant),
            "Incorrect operation"
        );
        assertEq(_preparedSetupData.permissions[2].where, address(dao));
        assertEq(_preparedSetupData.permissions[2].who, _plugin);
        assertEq(_preparedSetupData.permissions[2].condition, address(0));
        assertEq(
            _preparedSetupData.permissions[2].permissionId,
            keccak256("EXECUTE_PERMISSION")
        );
    }

    function test_PrepareUninstallationReturnsTheProperPermissions_1() public {
        // Prepare a dummy install
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );
        (
            address _dummyPlugin,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        LockToVetoPluginSetup.SetupPayload memory _payload = IPluginSetup
            .SetupPayload({
                plugin: _dummyPlugin,
                currentHelpers: _preparedSetupData.helpers,
                data: hex""
            });

        // Check uninstall
        PermissionLib.MultiTargetPermission[]
            memory _permissionChanges = pluginSetup.prepareUninstallation(
                address(dao),
                _payload
            );

        assertEq(
            _permissionChanges.length,
            3,
            "Incorrect permission changes length"
        );
        // 1
        assertEq(
            uint256(_permissionChanges[0].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[0].where, _dummyPlugin);
        assertEq(_permissionChanges[0].who, address(dao));
        assertEq(_permissionChanges[0].condition, address(0));
        assertEq(
            _permissionChanges[0].permissionId,
            keccak256("UPDATE_OPTIMISTIC_GOVERNANCE_SETTINGS_PERMISSION")
        );
        // 2
        assertEq(
            uint256(_permissionChanges[1].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[1].where, _dummyPlugin);
        assertEq(_permissionChanges[1].who, address(dao));
        assertEq(_permissionChanges[1].condition, address(0));
        assertEq(
            _permissionChanges[1].permissionId,
            keccak256("UPGRADE_PLUGIN_PERMISSION")
        );
        // 3
        assertEq(
            uint256(_permissionChanges[2].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[2].where, address(dao));
        assertEq(_permissionChanges[2].who, _dummyPlugin);
        assertEq(_permissionChanges[2].condition, address(0));
        assertEq(
            _permissionChanges[2].permissionId,
            keccak256("EXECUTE_PERMISSION")
        );
    }

    function test_PrepareUninstallationReturnsTheProperPermissions_2() public {
        // Prepare a dummy install
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(0x0),
            name: "Dummy Token",
            symbol: "DTK"
        });
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );
        (
            address _dummyPlugin,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        LockToVetoPluginSetup.SetupPayload memory _payload = IPluginSetup
            .SetupPayload({
                plugin: _dummyPlugin,
                currentHelpers: _preparedSetupData.helpers,
                data: hex""
            });

        // Check uninstall
        PermissionLib.MultiTargetPermission[]
            memory _permissionChanges = pluginSetup.prepareUninstallation(
                address(dao),
                _payload
            );

        assertEq(
            _permissionChanges.length,
            3,
            "Incorrect permission changes length"
        );
        // 1
        assertEq(
            uint256(_permissionChanges[0].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[0].where, _dummyPlugin);
        assertEq(_permissionChanges[0].who, address(dao));
        assertEq(_permissionChanges[0].condition, address(0));
        assertEq(
            _permissionChanges[0].permissionId,
            keccak256("UPDATE_OPTIMISTIC_GOVERNANCE_SETTINGS_PERMISSION")
        );
        // 2
        assertEq(
            uint256(_permissionChanges[1].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[1].where, _dummyPlugin);
        assertEq(_permissionChanges[1].who, address(dao));
        assertEq(_permissionChanges[1].condition, address(0));
        assertEq(
            _permissionChanges[1].permissionId,
            keccak256("UPGRADE_PLUGIN_PERMISSION")
        );
        // 3
        assertEq(
            uint256(_permissionChanges[2].operation),
            uint256(PermissionLib.Operation.Revoke),
            "Incorrect operation"
        );
        assertEq(_permissionChanges[2].where, address(dao));
        assertEq(_permissionChanges[2].who, _dummyPlugin);
        assertEq(_permissionChanges[2].condition, address(0));
        assertEq(
            _permissionChanges[2].permissionId,
            keccak256("EXECUTE_PERMISSION")
        );
    }

    function test_CreatesANewERC20Token() public {
        // new Token
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(0x0),
            name: "New Token",
            symbol: "NTK"
        });

        address[] memory receivers = new address[](1);
        receivers[0] = address(0x1234);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;
        mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,
            amounts: amounts
        });
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            // only used for GovernanceERC20 (when a token is not passed)
            mintSettings
        );
        (
            ,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        GovernanceERC20 _token = GovernanceERC20(_preparedSetupData.helpers[0]);
        assertEq(_token.balanceOf(address(0x1234)), 100);
        assertEq(_token.balanceOf(address(0x5678)), 0);
        assertEq(_token.balanceOf(address(0x0)), 0);

        assertEq(_token.name(), "New Token");
        assertEq(_token.symbol(), "NTK");
    }

    function test_UsesAnExistingGovernanceERC20Token() public {
        // Use existing governance token
        address[] memory receivers = new address[](2);
        receivers[0] = address(0x1234);
        receivers[1] = address(0x5678);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        mintSettings = GovernanceERC20.MintSettings({
            receivers: receivers,
            amounts: amounts
        });
        GovernanceERC20 _token = GovernanceERC20(
            payable(
                createProxyAndCall(
                    address(governanceERC20Base),
                    abi.encodeWithSelector(
                        GovernanceERC20.initialize.selector,
                        IDAO(dao),
                        "My Token",
                        "MTK",
                        mintSettings
                    )
                )
            )
        );
        tokenSettings = LockToVetoPluginSetup.TokenSettings({
            addr: address(_token),
            name: "",
            symbol: ""
        });
        bytes memory installationParams = pluginSetup.encodeInstallationParams(
            votingSettings,
            tokenSettings,
            mintSettings
        );
        (
            ,
            IPluginSetup.PreparedSetupData memory _preparedSetupData
        ) = pluginSetup.prepareInstallation(address(dao), installationParams);

        GovernanceWrappedERC20 _wrappedToken = GovernanceWrappedERC20(
            _preparedSetupData.helpers[0]
        );
        assertEq(_wrappedToken.name(), "My Token");
        assertEq(_wrappedToken.symbol(), "MTK");

        assertEq(_wrappedToken.balanceOf(address(0x1234)), 100);
        assertEq(_wrappedToken.balanceOf(address(0x5678)), 200);
        assertEq(_wrappedToken.balanceOf(address(0x0)), 0);
    }

    // HELPERS
    function createProxyAndCall(
        address _logic,
        bytes memory _data
    ) private returns (address) {
        return address(new ERC1967Proxy(_logic, _data));
    }
}
