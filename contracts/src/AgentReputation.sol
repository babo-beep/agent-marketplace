// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AgentReputation
 * @notice Track reputation scores for AI agents in the marketplace
 * @dev Reputation increases with successful trades and decreases with scams
 */
contract AgentReputation {
    // Reputation changes
    int256 public constant SUCCESS_REWARD = 10;
    int256 public constant SCAM_PENALTY = -100;

    // Agent reputation scores
    mapping(address => int256) private _reputations;
    mapping(address => uint256) private _successCount;
    mapping(address => uint256) private _scamCount;
    mapping(address => bool) private _isRegistered;

    address public marketplace;
    address public owner;

    // Events
    event AgentRegistered(address indexed agent, uint256 timestamp);
    event ReputationUpdated(
        address indexed agent,
        int256 newReputation,
        int256 change,
        string reason,
        uint256 timestamp
    );

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only marketplace can call");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Set the marketplace contract address
     * @param _marketplace Address of the marketplace contract
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplace = _marketplace;
    }

    /**
     * @notice Register a new agent
     * @param agent Address of the agent to register
     */
    function registerAgent(address agent) external {
        require(agent != address(0), "Invalid agent address");
        require(!_isRegistered[agent], "Agent already registered");

        _isRegistered[agent] = true;
        _reputations[agent] = 0;
        _successCount[agent] = 0;
        _scamCount[agent] = 0;

        emit AgentRegistered(agent, block.timestamp);
    }

    /**
     * @notice Record a successful transaction for an agent
     * @param agent Address of the agent
     */
    function recordSuccess(address agent) external onlyMarketplace {
        require(_isRegistered[agent], "Agent not registered");

        _reputations[agent] += SUCCESS_REWARD;
        _successCount[agent]++;

        emit ReputationUpdated(
            agent,
            _reputations[agent],
            SUCCESS_REWARD,
            "Successful transaction",
            block.timestamp
        );
    }

    /**
     * @notice Record a scam report against an agent
     * @param agent Address of the agent
     */
    function recordScam(address agent) external onlyMarketplace {
        require(_isRegistered[agent], "Agent not registered");

        _reputations[agent] += SCAM_PENALTY;
        _scamCount[agent]++;

        emit ReputationUpdated(
            agent,
            _reputations[agent],
            SCAM_PENALTY,
            "Scam reported",
            block.timestamp
        );
    }

    /**
     * @notice Get reputation score for an agent
     * @param agent Address of the agent
     * @return Reputation score
     */
    function getReputation(address agent) external view returns (int256) {
        return _reputations[agent];
    }

    /**
     * @notice Get detailed stats for an agent
     * @param agent Address of the agent
     * @return reputation Current reputation score
     * @return successCount Number of successful transactions
     * @return scamCount Number of scam reports
     * @return isRegistered Whether the agent is registered
     */
    function getAgentStats(address agent)
        external
        view
        returns (
            int256 reputation,
            uint256 successCount,
            uint256 scamCount,
            bool isRegistered
        )
    {
        return (
            _reputations[agent],
            _successCount[agent],
            _scamCount[agent],
            _isRegistered[agent]
        );
    }

    /**
     * @notice Check if an agent is registered
     * @param agent Address of the agent
     * @return Whether the agent is registered
     */
    function isAgentRegistered(address agent) external view returns (bool) {
        return _isRegistered[agent];
    }

    /**
     * @notice Check if an agent meets minimum reputation threshold
     * @param agent Address of the agent
     * @param minReputation Minimum reputation required
     * @return Whether the agent meets the threshold
     */
    function meetsThreshold(address agent, int256 minReputation)
        external
        view
        returns (bool)
    {
        return _reputations[agent] >= minReputation;
    }

    /**
     * @notice Get success rate for an agent (as percentage with 2 decimals)
     * @param agent Address of the agent
     * @return Success rate (e.g., 9500 = 95.00%)
     */
    function getSuccessRate(address agent) external view returns (uint256) {
        uint256 totalTransactions = _successCount[agent] + _scamCount[agent];
        if (totalTransactions == 0) {
            return 0;
        }
        return (_successCount[agent] * 10000) / totalTransactions;
    }
}
