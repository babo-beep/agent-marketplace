// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AgentReputation} from "../src/AgentReputation.sol";

contract AgentReputationTest is Test {
    AgentReputation public reputation;

    address public owner = address(this);
    address public marketplace = address(0x1);
    address public agent1 = address(0x2);
    address public agent2 = address(0x3);
    address public unauthorizedUser = address(0x4);

    event AgentRegistered(address indexed agent, uint256 timestamp);
    event ReputationUpdated(
        address indexed agent,
        int256 newReputation,
        int256 change,
        string reason,
        uint256 timestamp
    );

    function setUp() public {
        reputation = new AgentReputation();
        reputation.setMarketplace(marketplace);
    }

    function testRegisterAgent() public {
        vm.expectEmit(true, true, true, true);
        emit AgentRegistered(agent1, block.timestamp);
        
        reputation.registerAgent(agent1);
        
        assertTrue(reputation.isAgentRegistered(agent1));
        assertEq(reputation.getReputation(agent1), 0);
        
        (int256 rep, uint256 successCount, uint256 scamCount, bool isRegistered) = 
            reputation.getAgentStats(agent1);
        
        assertEq(rep, 0);
        assertEq(successCount, 0);
        assertEq(scamCount, 0);
        assertTrue(isRegistered);
    }

    function testRegisterAgentTwice() public {
        reputation.registerAgent(agent1);
        
        vm.expectRevert("Agent already registered");
        reputation.registerAgent(agent1);
    }

    function testRegisterAgentZeroAddress() public {
        vm.expectRevert("Invalid agent address");
        reputation.registerAgent(address(0));
    }

    function testRecordSuccess() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        vm.expectEmit(true, true, true, true);
        emit ReputationUpdated(agent1, 10, 10, "Successful transaction", block.timestamp);
        
        reputation.recordSuccess(agent1);
        
        assertEq(reputation.getReputation(agent1), 10);
        
        (int256 rep, uint256 successCount, uint256 scamCount, bool isRegistered) = 
            reputation.getAgentStats(agent1);
        
        assertEq(rep, 10);
        assertEq(successCount, 1);
        assertEq(scamCount, 0);
        
        vm.stopPrank();
    }

    function testRecordSuccessUnauthorized() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Only marketplace can call");
        reputation.recordSuccess(agent1);
        
        vm.stopPrank();
    }

    function testRecordSuccessUnregisteredAgent() public {
        vm.startPrank(marketplace);
        
        vm.expectRevert("Agent not registered");
        reputation.recordSuccess(agent1);
        
        vm.stopPrank();
    }

    function testRecordScam() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        vm.expectEmit(true, true, true, true);
        emit ReputationUpdated(agent1, -100, -100, "Scam reported", block.timestamp);
        
        reputation.recordScam(agent1);
        
        assertEq(reputation.getReputation(agent1), -100);
        
        (int256 rep, uint256 successCount, uint256 scamCount, bool isRegistered) = 
            reputation.getAgentStats(agent1);
        
        assertEq(rep, -100);
        assertEq(successCount, 0);
        assertEq(scamCount, 1);
        
        vm.stopPrank();
    }

    function testRecordScamUnauthorized() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Only marketplace can call");
        reputation.recordScam(agent1);
        
        vm.stopPrank();
    }

    function testMultipleSuccesses() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        for (uint i = 0; i < 5; i++) {
            reputation.recordSuccess(agent1);
        }
        
        assertEq(reputation.getReputation(agent1), 50);
        
        (int256 rep, uint256 successCount, , ) = reputation.getAgentStats(agent1);
        
        assertEq(rep, 50);
        assertEq(successCount, 5);
        
        vm.stopPrank();
    }

    function testMixedReputationChanges() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        // 3 successes
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        assertEq(reputation.getReputation(agent1), 30);
        
        // 1 scam
        reputation.recordScam(agent1);
        assertEq(reputation.getReputation(agent1), -70);
        
        // 2 more successes
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        assertEq(reputation.getReputation(agent1), -50);
        
        vm.stopPrank();
    }

    function testMeetsThreshold() public {
        reputation.registerAgent(agent1);
        
        // Initially meets threshold of 0
        assertTrue(reputation.meetsThreshold(agent1, 0));
        assertFalse(reputation.meetsThreshold(agent1, 10));
        
        vm.startPrank(marketplace);
        
        // Add 3 successes
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        
        assertTrue(reputation.meetsThreshold(agent1, 0));
        assertTrue(reputation.meetsThreshold(agent1, 30));
        assertFalse(reputation.meetsThreshold(agent1, 40));
        
        vm.stopPrank();
    }

    function testGetSuccessRate() public {
        reputation.registerAgent(agent1);
        
        // No transactions yet
        assertEq(reputation.getSuccessRate(agent1), 0);
        
        vm.startPrank(marketplace);
        
        // 4 successes, 1 scam = 80% success rate
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordScam(agent1);
        
        // Success rate should be 8000 (80.00%)
        assertEq(reputation.getSuccessRate(agent1), 8000);
        
        vm.stopPrank();
    }

    function testGetSuccessRateAllScams() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        // All scams
        reputation.recordScam(agent1);
        reputation.recordScam(agent1);
        
        // Success rate should be 0%
        assertEq(reputation.getSuccessRate(agent1), 0);
        
        vm.stopPrank();
    }

    function testGetSuccessRateAllSuccesses() public {
        reputation.registerAgent(agent1);
        
        vm.startPrank(marketplace);
        
        // All successes
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        
        // Success rate should be 10000 (100.00%)
        assertEq(reputation.getSuccessRate(agent1), 10000);
        
        vm.stopPrank();
    }

    function testSetMarketplace() public {
        address newMarketplace = address(0x5);
        
        reputation.setMarketplace(newMarketplace);
        assertEq(reputation.marketplace(), newMarketplace);
    }

    function testSetMarketplaceUnauthorized() public {
        address newMarketplace = address(0x5);
        
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Only owner can call");
        reputation.setMarketplace(newMarketplace);
        
        vm.stopPrank();
    }

    function testSetMarketplaceZeroAddress() public {
        vm.expectRevert("Invalid marketplace address");
        reputation.setMarketplace(address(0));
    }

    function testMultipleAgents() public {
        // Register multiple agents
        reputation.registerAgent(agent1);
        reputation.registerAgent(agent2);
        
        vm.startPrank(marketplace);
        
        // Agent 1 gets 2 successes
        reputation.recordSuccess(agent1);
        reputation.recordSuccess(agent1);
        
        // Agent 2 gets 1 success and 1 scam
        reputation.recordSuccess(agent2);
        reputation.recordScam(agent2);
        
        // Check agent 1
        assertEq(reputation.getReputation(agent1), 20);
        (int256 rep1, uint256 success1, uint256 scam1, ) = reputation.getAgentStats(agent1);
        assertEq(rep1, 20);
        assertEq(success1, 2);
        assertEq(scam1, 0);
        
        // Check agent 2
        assertEq(reputation.getReputation(agent2), -90);
        (int256 rep2, uint256 success2, uint256 scam2, ) = reputation.getAgentStats(agent2);
        assertEq(rep2, -90);
        assertEq(success2, 1);
        assertEq(scam2, 1);
        
        vm.stopPrank();
    }
}
