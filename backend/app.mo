/**
 * ImpactOracle - Cross-Chain Impact Verification Protocol
 * WCHL 2025 Submission by kptoo
 * 
 * Smart contract for verifying and monetizing real-world positive actions
 * across Bitcoin, Ethereum, and ICP using Chain Fusion technology.
 */

import Time "mo:base/Time";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Hash "mo:base/Hash";

actor ImpactOracle {
    
    // ============================================
    // DATA TYPES & STRUCTURES
    // ============================================
    
    /// Geographic location with coordinates and country
    public type Location = {
        latitude: Float;
        longitude: Float;
        country: Text;
    };
    
    /// Evidence submitted for impact verification
    public type Evidence = {
        imageUrl: Text;
        description: Text;
        timestamp: Int;
    };
    
    /// Core impact action structure
    public type ImpactAction = {
        id: Nat;
        submitter: Principal;
        actionType: Text; // "tree_plant", "beach_cleanup", "education", "elderly_care"
        location: Location;
        evidence: Evidence;
        verificationScore: Float;
        isVerified: Bool;
        impactTokens: Nat;
        carbonOffset: ?Float; // kg of CO2 offset
        socialImpact: ?Nat;   // social impact score
        createdAt: Int;
        verifiedAt: ?Int;
    };
    
    /// Impact tokens representing verified actions
    public type ImpactToken = {
        id: Nat;
        actionId: Nat;
        owner: Principal;
        tokenType: Text; // "TreeCoin", "CleanCoin", "EduCoin", "CareCoin"
        value: Nat;
        carbonEquivalent: ?Float;
        transferable: Bool;
        createdAt: Int;
    };
    
    /// Corporate buyers for ESG compliance
    public type CorporateBuyer = {
        principal: Principal;
        companyName: Text;
        esgBudget: Nat;
        requiredImpactTypes: [Text];
        autoButEnabled: Bool;
        totalPurchased: Nat;
    };
    
    /// Platform statistics
    public type Stats = {
        totalActions: Nat;
        totalTokens: Nat;
        totalValue: Nat;
        totalCarbonOffset: Float;
        activeUsers: Nat;
        corporateBuyers: Nat;
    };
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    // Stable variables for upgrade persistence
    private stable var nextActionId: Nat = 1;
    private stable var nextTokenId: Nat = 1;
    private stable var platformFeeRate: Float = 0.02; // 2% platform fee
    
    // Hash functions for HashMap
    private func natHash(n: Nat) : Hash.Hash {
        Text.hash(Nat.toText(n))
    };
    
    private func principalHash(p: Principal) : Hash.Hash {
        Text.hash(Principal.toText(p))
    };
    
    // Storage HashMaps
    private var actions = HashMap.HashMap<Nat, ImpactAction>(100, Nat.equal, natHash);
    private var tokens = HashMap.HashMap<Nat, ImpactToken>(100, Nat.equal, natHash);
    private var corporateBuyers = HashMap.HashMap<Principal, CorporateBuyer>(50, Principal.equal, principalHash);
    private var userActions = HashMap.HashMap<Principal, [Nat]>(100, Principal.equal, principalHash);
    private var userTokens = HashMap.HashMap<Principal, [Nat]>(100, Principal.equal, principalHash);
    
    // ============================================
    // CONSTANTS & CONFIGURATION
    // ============================================
    
    private let MIN_VERIFICATION_SCORE: Float = 0.75;
    
    // Token rewards for different action types
    private let TREE_PLANT_REWARD: Nat = 100;
    private let CLEANUP_REWARD: Nat = 50;
    private let EDUCATION_REWARD: Nat = 200;
    private let CARE_REWARD: Nat = 150;
    
    // Carbon offset values (kg CO2 per action)
    private let TREE_CARBON_OFFSET: Float = 22.0;
    private let CLEANUP_CARBON_OFFSET: Float = 5.0;
    
    // ============================================
    // CORE IMPACT ACTION FUNCTIONS
    // ============================================
    
    /// Submit a new impact action for verification
    public shared(msg) func submitImpactAction(
        actionType: Text,
        location: Location,
        evidence: Evidence
    ) : async Result.Result<Nat, Text> {
        
        // Validate input
        if (Text.size(actionType) == 0) {
            return #err("Action type cannot be empty");
        };
        
        if (Text.size(evidence.description) < 10) {
            return #err("Description must be at least 10 characters");
        };
        
        let actionId = nextActionId;
        nextActionId += 1;
        
        let action: ImpactAction = {
            id = actionId;
            submitter = msg.caller;
            actionType = actionType;
            location = location;
            evidence = evidence;
            verificationScore = 0.0;
            isVerified = false;
            impactTokens = 0;
            carbonOffset = null;
            socialImpact = null;
            createdAt = Time.now();
            verifiedAt = null;
        };
        
        // Store the action
        actions.put(actionId, action);
        
        // Add to user's action list
        switch (userActions.get(msg.caller)) {
            case (?existing) {
                userActions.put(msg.caller, Array.append(existing, [actionId]));
            };
            case null {
                userActions.put(msg.caller, [actionId]);
            };
        };
        
        // Trigger verification process (async)
        ignore verifyAction(actionId);
        
        #ok(actionId)
    };
    
    /// AI-powered verification of impact actions
    private func verifyAction(actionId: Nat) : async () {
        switch (actions.get(actionId)) {
            case (?action) {
                // Simulate AI verification with high confidence for demo
                // In production, this would integrate with:
                // - Computer vision APIs via HTTPS outcalls
                // - GPS validation services
                // - Satellite imagery analysis
                // - Anti-fraud detection algorithms
                
                let verificationScore = await simulateAIVerification(action);
                
                if (verificationScore >= MIN_VERIFICATION_SCORE) {
                    let rewards = calculateRewards(action.actionType);
                    let carbonOffset = calculateCarbonOffset(action.actionType);
                    let socialImpact = calculateSocialImpact(action.actionType);
                    
                    let verifiedAction: ImpactAction = {
                        action with
                        verificationScore = verificationScore;
                        isVerified = true;
                        impactTokens = rewards;
                        carbonOffset = carbonOffset;
                        socialImpact = socialImpact;
                        verifiedAt = ?Time.now();
                    };
                    
                    actions.put(actionId, verifiedAction);
                    
                    // Mint impact tokens
                    ignore mintImpactTokens(actionId, action.submitter, rewards, action.actionType);
                    
                    // Check for corporate auto-buyers
                    ignore processAutoBuyers(actionId);
                };
            };
            case null { 
                // Action not found - should not happen
            };
        };
    };
    
    /// Simulate AI verification (replace with real AI in production)
    private func simulateAIVerification(action: ImpactAction) : async Float {
        // Simulate different verification scores based on action type
        // Real implementation would use HTTPS outcalls to:
        // - Computer vision services for photo analysis
        // - GPS validation APIs
        // - Satellite data providers
        // - Fraud detection services
        
        switch (action.actionType) {
            case ("tree_plant") { 0.94 };      // High confidence for tree planting
            case ("beach_cleanup") { 0.89 };   // Good confidence for cleanup
            case ("education") { 0.91 };       // High confidence for education
            case ("elderly_care") { 0.87 };    // Good confidence for care
            case (_) { 0.65 };                 // Lower confidence for unknown types
        };
    };
    
    // ============================================
    // TOKEN MANAGEMENT FUNCTIONS
    // ============================================
    
    /// Mint impact tokens for verified actions
    private func mintImpactTokens(
        actionId: Nat,
        recipient: Principal,
        amount: Nat,
        actionType: Text
    ) : async Nat {
        let tokenId = nextTokenId;
        nextTokenId += 1;
        
        let tokenType = getTokenName(actionType);
        
        let token: ImpactToken = {
            id = tokenId;
            actionId = actionId;
            owner = recipient;
            tokenType = tokenType;
            value = amount;
            carbonEquivalent = calculateCarbonOffset(actionType);
            transferable = true;
            createdAt = Time.now();
        };
        
        tokens.put(tokenId, token);
        
        // Add to user's token list
        switch (userTokens.get(recipient)) {
            case (?existing) {
                userTokens.put(recipient, Array.append(existing, [tokenId]));
            };
            case null {
                userTokens.put(recipient, [tokenId]);
            };
        };
        
        tokenId
    };
    
    /// Transfer tokens between users
    public shared(msg) func transferToken(tokenId: Nat, to: Principal) : async Result.Result<(), Text> {
        switch (tokens.get(tokenId)) {
            case (?token) {
                if (token.owner != msg.caller) {
                    return #err("Not authorized to transfer this token");
                };
                
                if (not token.transferable) {
                    return #err("Token is not transferable");
                };
                
                let updatedToken = { token with owner = to };
                tokens.put(tokenId, updatedToken);
                
                // Update user token lists
                // Remove from sender
                switch (userTokens.get(msg.caller)) {
                    case (?senderTokens) {
                        let filtered = Array.filter<Nat>(senderTokens, func(id) = id != tokenId);
                        userTokens.put(msg.caller, filtered);
                    };
                    case null { };
                };
                
                // Add to recipient
                switch (userTokens.get(to)) {
                    case (?recipientTokens) {
                        userTokens.put(to, Array.append(recipientTokens, [tokenId]));
                    };
                    case null {
                        userTokens.put(to, [tokenId]);
                    };
                };
                
                #ok()
            };
            case null {
                #err("Token not found")
            };
        };
    };
    
    // ============================================
    // CORPORATE ESG FUNCTIONS
    // ============================================
    
    /// Register a corporate buyer for ESG compliance
    public shared(msg) func registerCorporate(
        companyName: Text,
        esgBudget: Nat,
        requiredImpactTypes: [Text],
        autoButEnabled: Bool
    ) : async Result.Result<(), Text> {
        
        if (Text.size(companyName) == 0) {
            return #err("Company name cannot be empty");
        };
        
        let buyer: CorporateBuyer = {
            principal = msg.caller;
            companyName = companyName;
            esgBudget = esgBudget;
            requiredImpactTypes = requiredImpactTypes;
            autoButEnabled = autoButEnabled;
            totalPurchased = 0;
        };
        
        corporateBuyers.put(msg.caller, buyer);
        #ok()
    };
    
    /// Process automatic purchases for corporate buyers
    private func processAutoBuyers(actionId: Nat) : async () {
        switch (actions.get(actionId)) {
            case (?action) {
                for ((principal, buyer) in corporateBuyers.entries()) {
                    if (buyer.autoButEnabled and 
                        Array.find<Text>(buyer.requiredImpactTypes, func(t) = t == action.actionType) != null) {
                        
                        // In production, this would trigger:
                        // - Cross-chain payment via Chain Fusion
                        // - Bitcoin/Ethereum transaction processing
                        // - ESG compliance record updates
                        // - Real-time corporate dashboard updates
                        
                        // For demo, we just log the match
                        ignore updateCorporatePurchase(principal, action.impactTokens);
                    };
                };
            };
            case null { };
        };
    };
    
    /// Update corporate purchase records
    private func updateCorporatePurchase(principal: Principal, amount: Nat) : async () {
        switch (corporateBuyers.get(principal)) {
            case (?buyer) {
                let updatedBuyer = { buyer with totalPurchased = buyer.totalPurchased + amount };
                corporateBuyers.put(principal, updatedBuyer);
            };
            case null { };
        };
    };
    
    // ============================================
    // UTILITY & CALCULATION FUNCTIONS
    // ============================================
    
    /// Calculate token rewards based on action type
    private func calculateRewards(actionType: Text) : Nat {
        switch (actionType) {
            case ("tree_plant") { TREE_PLANT_REWARD };
            case ("beach_cleanup") { CLEANUP_REWARD };
            case ("education") { EDUCATION_REWARD };
            case ("elderly_care") { CARE_REWARD };
            case (_) { 25 }; // Default reward for unknown types
        };
    };
    
    /// Calculate carbon offset for environmental actions
    private func calculateCarbonOffset(actionType: Text) : ?Float {
        switch (actionType) {
            case ("tree_plant") { ?TREE_CARBON_OFFSET };
            case ("beach_cleanup") { ?CLEANUP_CARBON_OFFSET };
            case (_) { null };
        };
    };
    
    /// Calculate social impact score
    private func calculateSocialImpact(actionType: Text) : ?Nat {
        switch (actionType) {
            case ("education") { ?100 };      // High social impact
            case ("elderly_care") { ?80 };    // Good social impact
            case ("tree_plant") { ?40 };      // Some social impact
            case ("beach_cleanup") { ?30 };   // Some social impact
            case (_) { null };
        };
    };
    
    /// Get token name for action type
    private func getTokenName(actionType: Text) : Text {
        switch (actionType) {
            case ("tree_plant") { "TreeCoin" };
            case ("beach_cleanup") { "CleanCoin" };
            case ("education") { "EduCoin" };
            case ("elderly_care") { "CareCoin" };
            case (_) { "ImpactCoin" };
        };
    };
    
    // ============================================
    // QUERY FUNCTIONS
    // ============================================
    
    /// Get a specific impact action by ID
    public query func getAction(actionId: Nat) : async ?ImpactAction {
        actions.get(actionId)
    };
    
    /// Get all actions for a specific user
    public query func getUserActions(user: Principal) : async [Nat] {
        switch (userActions.get(user)) {
            case (?actionIds) { actionIds };
            case null { [] };
        };
    };
    
    /// Get all verified impact actions
    public query func getVerifiedActions() : async [ImpactAction] {
        var verified: [ImpactAction] = [];
        for ((id, action) in actions.entries()) {
            if (action.isVerified) {
                verified := Array.append(verified, [action]);
            };
        };
        verified
    };
    
    /// Get all tokens for a specific user
    public query func getUserTokens(user: Principal) : async [ImpactToken] {
        switch (userTokens.get(user)) {
            case (?tokenIds) {
                var userTokenArray: [ImpactToken] = [];
                for (tokenId in tokenIds.vals()) {
                    switch (tokens.get(tokenId)) {
                        case (?token) {
                            userTokenArray := Array.append(userTokenArray, [token]);
                        };
                        case null { };
                    };
                };
                userTokenArray
            };
            case null { [] };
        };
    };
    
    /// Get tokens available for trading
    public query func getMarketplaceTokens() : async [ImpactToken] {
        var marketTokens: [ImpactToken] = [];
        for ((id, token) in tokens.entries()) {
            if (token.transferable) {
                marketTokens := Array.append(marketTokens, [token]);
            };
        };
        marketTokens
    };
    
    /// Get platform statistics
    public query func getStats() : async Stats {
        var totalActions = 0;
        var totalTokens = 0;
        var totalValue = 0;
        var totalCarbonOffset: Float = 0.0;
        var activeUsers = userActions.size();
        var corporateBuyerCount = corporateBuyers.size();
        
        // Calculate totals from verified actions
        for ((id, action) in actions.entries()) {
            totalActions += 1;
            if (action.isVerified) {
                totalTokens += action.impactTokens;
                totalValue += action.impactTokens * 50; // $0.50 per token
                
                switch (action.carbonOffset) {
                    case (?offset) {
                        totalCarbonOffset += offset;
                    };
                    case null { };
                };
            };
        };
        
        {
            totalActions = totalActions;
            totalTokens = totalTokens;
            totalValue = totalValue;
            totalCarbonOffset = totalCarbonOffset;
            activeUsers = activeUsers;
            corporateBuyers = corporateBuyerCount;
        }
    };
    
    /// Get corporate buyer information
    public query func getCorporateBuyer(principal: Principal) : async ?CorporateBuyer {
        corporateBuyers.get(principal)
    };
    
    /// Simple greeting function (from original template)
    public query func greet(name: Text) : async Text {
        return "Welcome to ImpactOracle, " # name # "! 🌍 Turn your verified good deeds into cross-chain digital gold! 💰";
    };
    
    // ============================================
    // ADMIN FUNCTIONS (Future Implementation)
    // ============================================
    
    /// Update platform fee rate (admin only)
    public func updatePlatformFee(newRate: Float) : async Result.Result<(), Text> {
        // TODO: Add admin authorization check
        if (newRate < 0.0 or newRate > 0.1) {
            return #err("Fee rate must be between 0% and 10%");
        };
        
        platformFeeRate := newRate;
        #ok()
    };
    
    /// Get current platform fee rate
    public query func getPlatformFeeRate() : async Float {
        platformFeeRate
    };
}
