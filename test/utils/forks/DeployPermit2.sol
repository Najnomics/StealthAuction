// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {Permit2Bytecode} from "./Permit2Bytecode.sol";

/// @title DeployPermit2
/// @notice Utility for deploying Permit2 in test environments
contract DeployPermit2 is Test {
    IAllowanceTransfer permit2;

    function deployPermit2() internal {
        if (address(permit2) == address(0)) {
            permit2 = IAllowanceTransfer(Permit2Bytecode.deploy());
            vm.label(address(permit2), "Permit2");
        }
    }

    function deployBytecode(bytes memory bytecode) internal returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), 0)
        }
        require(addr != address(0), "DeployPermit2: deployment failed");
    }
}
