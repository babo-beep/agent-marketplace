// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AgentMarketplace} from "../src/AgentMarketplace.sol";
import {AgentReputation} from "../src/AgentReputation.sol";

contract AgentMarketplaceTest is Test {
    AgentMarketplace public marketplace;
    AgentReputation public reputation;

    address public owner = address(this);
    address public seller = address(0x1);
    address public buyer = address(0x2);
    address public sellerAgent = address(0x3);
    address public buyerAgent = address(0x4);
    address public unauthorizedUser = address(0x5);

    uint256 constant ITEM_PRICE = 1 ether;
    string constant ITEM_DATA = '{"name":"iPhone 13","condition":"good","description":"Used iPhone"}';

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

    function setUp() public {
        // Deploy reputation contract
        reputation = new AgentReputation();
        
        // Deploy marketplace contract
        marketplace = new AgentMarketplace(address(reputation));
        
        // Set marketplace in reputation contract
        reputation.setMarketplace(address(marketplace));

        // Register agents
        reputation.registerAgent(sellerAgent);
        reputation.registerAgent(buyerAgent);

        // Give test accounts some ETH
        vm.deal(seller, 10 ether);
        vm.deal(buyer, 10 ether);
    }

    function testListItem() public {
        vm.startPrank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit ListingCreated(0, seller, sellerAgent, ITEM_PRICE, ITEM_DATA, block.timestamp);
        
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);
        
        assertEq(listingId, 0);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(listing.seller, seller);
        assertEq(listing.sellerAgent, sellerAgent);
        assertEq(listing.price, ITEM_PRICE);
        assertEq(listing.itemData, ITEM_DATA);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.Active));
        
        vm.stopPrank();
    }

    function testListItemWithZeroPrice() public {
        vm.startPrank(seller);
        
        vm.expectRevert("Price must be greater than 0");
        marketplace.listItem(ITEM_DATA, 0, seller, sellerAgent);
        
        vm.stopPrank();
    }

    function testRequestPurchase() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.startPrank(buyer);
        
        vm.expectEmit(true, true, true, true);
        emit PurchaseRequested(listingId, buyer, buyerAgent, block.timestamp);
        
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(listing.buyer, buyer);
        assertEq(listing.buyerAgent, buyerAgent);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.PendingPurchase));
        
        vm.stopPrank();
    }

    function testRequestPurchaseWithIncorrectPayment() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Try to request purchase with wrong amount
        vm.startPrank(buyer);
        
        vm.expectRevert("Incorrect payment amount");
        marketplace.requestPurchase{value: 0.5 ether}(listingId, buyer, buyerAgent);
        
        vm.stopPrank();
    }

    function testConfirmPurchase() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Confirm purchase
        vm.startPrank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit PurchaseConfirmed(listingId, seller, block.timestamp);
        
        marketplace.confirmPurchase(listingId);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.AwaitingDelivery));
        
        vm.stopPrank();
    }

    function testConfirmPurchaseUnauthorized() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Try to confirm as unauthorized user
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Not the seller");
        marketplace.confirmPurchase(listingId);
        
        vm.stopPrank();
    }

    function testReleaseFunds() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Confirm purchase
        vm.prank(seller);
        marketplace.confirmPurchase(listingId);

        // Record seller's initial balance
        uint256 sellerBalanceBefore = seller.balance;

        // Release funds
        vm.startPrank(buyer);
        
        vm.expectEmit(true, true, true, true);
        emit FundsReleased(listingId, seller, ITEM_PRICE, block.timestamp);
        
        marketplace.releaseFunds(listingId);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.Completed));
        
        // Check seller received payment
        assertEq(seller.balance, sellerBalanceBefore + ITEM_PRICE);
        
        // Check reputation updated
        assertEq(reputation.getReputation(sellerAgent), 10);
        assertEq(reputation.getReputation(buyerAgent), 10);
        
        vm.stopPrank();
    }

    function testRefund() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Record buyer's balance before refund
        uint256 buyerBalanceBefore = buyer.balance;

        // Refund
        vm.startPrank(seller);
        
        vm.expectEmit(true, true, true, true);
        emit ListingRefunded(listingId, buyer, ITEM_PRICE, block.timestamp);
        
        marketplace.refund(listingId);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.Refunded));
        
        // Check buyer received refund
        assertEq(buyer.balance, buyerBalanceBefore + ITEM_PRICE);
        
        vm.stopPrank();
    }

    function testCancelListing() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Cancel listing
        vm.startPrank(seller);
        marketplace.cancelListing(listingId);
        
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.Cancelled));
        
        vm.stopPrank();
    }

    function testCancelListingWithPendingPurchase() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Try to cancel
        vm.startPrank(seller);
        
        vm.expectRevert("Cannot cancel at this stage");
        marketplace.cancelListing(listingId);
        
        vm.stopPrank();
    }

    function testReportScam() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Record reputation before
        int256 buyerAgentReputationBefore = reputation.getReputation(buyerAgent);

        // Report scam
        vm.startPrank(seller);
        marketplace.reportScam(listingId, buyerAgent);
        
        // Check reputation decreased
        int256 buyerAgentReputationAfter = reputation.getReputation(buyerAgent);
        assertEq(buyerAgentReputationAfter, buyerAgentReputationBefore - 100);
        
        vm.stopPrank();
    }

    function testReportScamUnauthorized() public {
        // Create listing
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // Request purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // Try to report as unauthorized user
        vm.startPrank(unauthorizedUser);
        
        vm.expectRevert("Not authorized to report");
        marketplace.reportScam(listingId, buyerAgent);
        
        vm.stopPrank();
    }

    function testGetTotalListings() public {
        assertEq(marketplace.getTotalListings(), 0);

        vm.startPrank(seller);
        marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);
        assertEq(marketplace.getTotalListings(), 1);

        marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);
        assertEq(marketplace.getTotalListings(), 2);
        
        vm.stopPrank();
    }

    function testFullTransactionFlow() public {
        // 1. Seller lists item
        vm.prank(seller);
        uint256 listingId = marketplace.listItem(ITEM_DATA, ITEM_PRICE, seller, sellerAgent);

        // 2. Buyer requests purchase
        vm.prank(buyer);
        marketplace.requestPurchase{value: ITEM_PRICE}(listingId, buyer, buyerAgent);

        // 3. Seller confirms purchase
        vm.prank(seller);
        marketplace.confirmPurchase(listingId);

        // 4. Buyer releases funds after delivery
        uint256 sellerBalanceBefore = seller.balance;
        
        vm.prank(buyer);
        marketplace.releaseFunds(listingId);

        // Verify final state
        AgentMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(uint(listing.status), uint(AgentMarketplace.ListingStatus.Completed));
        assertEq(seller.balance, sellerBalanceBefore + ITEM_PRICE);
        assertEq(reputation.getReputation(sellerAgent), 10);
        assertEq(reputation.getReputation(buyerAgent), 10);
    }
}
