// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AgentReputation.sol";

/**
 * @title AgentMarketplace
 * @notice Escrow marketplace for AI agents to help humans buy/sell items
 * @dev Implements owner approval flow and reputation-gated transactions
 */
contract AgentMarketplace {
    AgentReputation public reputationContract;

    enum ListingStatus {
        Active,
        PendingPurchase,
        AwaitingDelivery,
        Completed,
        Cancelled,
        Refunded
    }

    struct Listing {
        uint256 id;
        address seller;
        address sellerAgent;
        string itemData; // JSON metadata
        uint256 price;
        ListingStatus status;
        address buyer;
        address buyerAgent;
        uint256 createdAt;
        uint256 updatedAt;
    }

    uint256 private _listingIdCounter;
    mapping(uint256 => Listing) public listings;
    
    // Minimum reputation required to transact
    uint256 public constant MIN_REPUTATION = 0;
    // Reputation reward for successful transaction
    uint256 public constant REPUTATION_REWARD = 10;

    // Events for API indexing
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed sellerAgent,
        uint256 price,
        string itemData,
        uint256 timestamp
    );

    event PurchaseRequested(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed buyerAgent,
        uint256 timestamp
    );

    event PurchaseConfirmed(
        uint256 indexed listingId,
        address indexed seller,
        uint256 timestamp
    );

    event FundsReleased(
        uint256 indexed listingId,
        address indexed seller,
        uint256 amount,
        uint256 timestamp
    );

    event ListingRefunded(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 amount,
        uint256 timestamp
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller,
        uint256 timestamp
    );

    // Modifiers
    modifier onlySeller(uint256 listingId) {
        require(listings[listingId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier onlyBuyer(uint256 listingId) {
        require(listings[listingId].buyer == msg.sender, "Not the buyer");
        _;
    }

    modifier listingExists(uint256 listingId) {
        require(listings[listingId].seller != address(0), "Listing does not exist");
        _;
    }

    modifier hasMinimumReputation(address agent) {
        require(
            reputationContract.getReputation(agent) >= int256(MIN_REPUTATION),
            "Agent reputation too low"
        );
        _;
    }

    constructor(address _reputationContract) {
        reputationContract = AgentReputation(_reputationContract);
    }

    /**
     * @notice Create a new listing
     * @param itemData JSON string with item metadata
     * @param price Price in wei
     * @param seller Owner of the item
     * @param sellerAgent AI agent representing the seller
     */
    function listItem(
        string calldata itemData,
        uint256 price,
        address seller,
        address sellerAgent
    ) external hasMinimumReputation(sellerAgent) returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(seller != address(0), "Invalid seller address");
        require(sellerAgent != address(0), "Invalid agent address");

        uint256 listingId = _listingIdCounter++;

        listings[listingId] = Listing({
            id: listingId,
            seller: seller,
            sellerAgent: sellerAgent,
            itemData: itemData,
            price: price,
            status: ListingStatus.Active,
            buyer: address(0),
            buyerAgent: address(0),
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        emit ListingCreated(
            listingId,
            seller,
            sellerAgent,
            price,
            itemData,
            block.timestamp
        );

        return listingId;
    }

    /**
     * @notice Agent requests to purchase an item (must be confirmed by owner)
     * @param listingId ID of the listing
     * @param buyer Owner who will receive the item
     * @param buyerAgent AI agent representing the buyer
     */
    function requestPurchase(
        uint256 listingId,
        address buyer,
        address buyerAgent
    ) external payable listingExists(listingId) hasMinimumReputation(buyerAgent) {
        Listing storage listing = listings[listingId];
        
        require(listing.status == ListingStatus.Active, "Listing not available");
        require(msg.value == listing.price, "Incorrect payment amount");
        require(buyer != address(0), "Invalid buyer address");
        require(buyerAgent != address(0), "Invalid agent address");
        require(buyer != listing.seller, "Cannot buy your own item");

        listing.buyer = buyer;
        listing.buyerAgent = buyerAgent;
        listing.status = ListingStatus.PendingPurchase;
        listing.updatedAt = block.timestamp;

        emit PurchaseRequested(listingId, buyer, buyerAgent, block.timestamp);
    }

    /**
     * @notice Seller confirms the purchase request
     * @param listingId ID of the listing
     */
    function confirmPurchase(uint256 listingId)
        external
        onlySeller(listingId)
        listingExists(listingId)
    {
        Listing storage listing = listings[listingId];
        
        require(listing.status == ListingStatus.PendingPurchase, "No pending purchase");

        listing.status = ListingStatus.AwaitingDelivery;
        listing.updatedAt = block.timestamp;

        emit PurchaseConfirmed(listingId, msg.sender, block.timestamp);
    }

    /**
     * @notice Release funds to seller after successful delivery
     * @param listingId ID of the listing
     */
    function releaseFunds(uint256 listingId)
        external
        onlyBuyer(listingId)
        listingExists(listingId)
    {
        Listing storage listing = listings[listingId];
        
        require(listing.status == ListingStatus.AwaitingDelivery, "Not awaiting delivery");

        listing.status = ListingStatus.Completed;
        listing.updatedAt = block.timestamp;

        // Update reputation for both agents
        reputationContract.recordSuccess(listing.sellerAgent);
        reputationContract.recordSuccess(listing.buyerAgent);

        // Transfer funds to seller
        uint256 amount = listing.price;
        (bool success, ) = listing.seller.call{value: amount}("");
        require(success, "Transfer failed");

        emit FundsReleased(listingId, listing.seller, amount, block.timestamp);
    }

    /**
     * @notice Refund buyer if something goes wrong
     * @param listingId ID of the listing
     */
    function refund(uint256 listingId)
        external
        onlySeller(listingId)
        listingExists(listingId)
    {
        Listing storage listing = listings[listingId];
        
        require(
            listing.status == ListingStatus.PendingPurchase ||
            listing.status == ListingStatus.AwaitingDelivery,
            "Cannot refund at this stage"
        );

        listing.status = ListingStatus.Refunded;
        listing.updatedAt = block.timestamp;

        // Refund buyer
        uint256 amount = listing.price;
        (bool success, ) = listing.buyer.call{value: amount}("");
        require(success, "Refund failed");

        emit ListingRefunded(listingId, listing.buyer, amount, block.timestamp);
    }

    /**
     * @notice Cancel an active listing (only if no pending purchase)
     * @param listingId ID of the listing
     */
    function cancelListing(uint256 listingId)
        external
        onlySeller(listingId)
        listingExists(listingId)
    {
        Listing storage listing = listings[listingId];
        
        require(listing.status == ListingStatus.Active, "Cannot cancel at this stage");

        listing.status = ListingStatus.Cancelled;
        listing.updatedAt = block.timestamp;

        emit ListingCancelled(listingId, msg.sender, block.timestamp);
    }

    /**
     * @notice Get listing details
     * @param listingId ID of the listing
     */
    function getListing(uint256 listingId)
        external
        view
        listingExists(listingId)
        returns (Listing memory)
    {
        return listings[listingId];
    }

    /**
     * @notice Get total number of listings created
     */
    function getTotalListings() external view returns (uint256) {
        return _listingIdCounter;
    }

    /**
     * @notice Report a scam (penalize agent reputation)
     * @param listingId ID of the listing
     * @param agentToReport Address of the agent to report
     */
    function reportScam(uint256 listingId, address agentToReport)
        external
        listingExists(listingId)
    {
        Listing storage listing = listings[listingId];
        
        // Only involved parties can report
        require(
            msg.sender == listing.seller || msg.sender == listing.buyer,
            "Not authorized to report"
        );
        
        // Only report involved agents
        require(
            agentToReport == listing.sellerAgent || agentToReport == listing.buyerAgent,
            "Agent not involved in this listing"
        );

        reputationContract.recordScam(agentToReport);
    }
}
