// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentReputation} from "../src/AgentReputation.sol";
import {AgentMarketplace} from "../src/AgentMarketplace.sol";

/**
 * @title Deploy
 * @notice Deployment script for AgentMarketplace and AgentReputation contracts
 * @dev Run with: forge script script/Deploy.s.sol:Deploy --rpc-url <RPC_URL> --broadcast
 */
contract Deploy is Script {
    function run() external returns (AgentMarketplace, AgentReputation) {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AgentReputation contract
        console.log("Deploying AgentReputation...");
        AgentReputation reputation = new AgentReputation();
        console.log("AgentReputation deployed at:", address(reputation));

        // 2. Deploy AgentMarketplace contract
        console.log("Deploying AgentMarketplace...");
        AgentMarketplace marketplace = new AgentMarketplace(address(reputation));
        console.log("AgentMarketplace deployed at:", address(marketplace));

        // 3. Set marketplace address in reputation contract
        console.log("Setting marketplace address in reputation contract...");
        reputation.setMarketplace(address(marketplace));
        console.log("Marketplace address set successfully");

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("AgentReputation:", address(reputation));
        console.log("AgentMarketplace:", address(marketplace));
        console.log("Owner:", reputation.owner());
        console.log("===========================\n");

        return (marketplace, reputation);
    }
}

/**
 * @title DeployLocal
 * @notice Deployment script for local testing with test agents
 */
contract DeployLocal is Script {
    function run() external returns (AgentMarketplace, AgentReputation, address, address) {
        // Use test key for local deployment
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AgentReputation contract
        console.log("Deploying AgentReputation...");
        AgentReputation reputation = new AgentReputation();
        console.log("AgentReputation deployed at:", address(reputation));

        // 2. Deploy AgentMarketplace contract
        console.log("Deploying AgentMarketplace...");
        AgentMarketplace marketplace = new AgentMarketplace(address(reputation));
        console.log("AgentMarketplace deployed at:", address(marketplace));

        // 3. Set marketplace address in reputation contract
        console.log("Setting marketplace address in reputation contract...");
        reputation.setMarketplace(address(marketplace));

        // 4. Create and register test agents
        address testAgent1 = address(0x1234567890123456789012345678901234567891);
        address testAgent2 = address(0x1234567890123456789012345678901234567892);
        
        console.log("Registering test agents...");
        reputation.registerAgent(testAgent1);
        reputation.registerAgent(testAgent2);
        console.log("Test Agent 1:", testAgent1);
        console.log("Test Agent 2:", testAgent2);

        vm.stopBroadcast();

        console.log("\n=== Local Deployment Summary ===");
        console.log("AgentReputation:", address(reputation));
        console.log("AgentMarketplace:", address(marketplace));
        console.log("Test Agent 1:", testAgent1);
        console.log("Test Agent 2:", testAgent2);
        console.log("================================\n");

        return (marketplace, reputation, testAgent1, testAgent2);
    }
}
