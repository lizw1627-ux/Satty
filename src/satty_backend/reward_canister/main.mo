import Types "../common/types";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Random "mo:base/Random";

actor RewardCanister {
    type Winner = Types.Winner;
    type QuestId = Types.QuestId;
    type UserId = Types.UserId;
    type SubmissionId = Types.SubmissionId;
    
    // ckBTC Ledger Interface
    type Account = Types.Account;
    type TransferArg = Types.TransferArg;
    type TransferResult = Types.TransferResult;
    
    // Ledger canister reference (mainnet ckBTC)
    let CKBTC_LEDGER = "mxzaz-hqaaa-aaaar-qaada-cai";
    let ckbtcLedger = actor(CKBTC_LEDGER) : actor {
        icrc1_transfer : (TransferArg) -> async TransferResult;
        icrc1_balance_of : (Account) -> async Nat;
    };
    
    // Stable storage
    stable var stableWinners: [(QuestId, [Winner])] = [];
    
    // Runtime storage
    var winners = HashMap.HashMap<QuestId, [Winner]>(10, Nat.equal, Nat.hash);
    
    // Persistence
    system func preupgrade() {
        stableWinners := Iter.toArray(winners.entries());
    };
    
    system func postupgrade() {
        winners := HashMap.fromIter<QuestId, [Winner]>(
            stableWinners.vals(),
            stableWinners.size(),
            Nat.equal,
            Nat.hash
        );
        stableWinners := [];
    };
    
    // Select winners using time-based randomness
    public func selectWinners(
        questId: QuestId,
        verifiedSubmissions: [Types.QuestSubmission],
        maxWinners: Nat,
        rewardPerWinner: Nat
    ): async Result.Result<[Winner], Text> {
        
        if (verifiedSubmissions.size() == 0) {
            return #err("No verified submissions found");
        };
        
        // Generate pseudo-random seed from submission timestamps
        var seed: Nat = 0;
        for (submission in verifiedSubmissions.vals()) {
            seed := (seed + Int.abs(submission.submittedAt)) % 1000000000;
        };
        
        // Determine actual number of winners
        let numWinners = Nat.min(maxWinners, verifiedSubmissions.size());
        
        // Fisher-Yates shuffle using timestamp-based randomness
        let submissions = Array.thaw<Types.QuestSubmission>(verifiedSubmissions);
        var i = submissions.size();
        
        while (i > 1) {
            i -= 1;
            seed := (seed * 1103515245 + 12345) % 2147483648;
            let j = seed % (i + 1);
            
            let temp = submissions[i];
            submissions[i] := submissions[j];
            submissions[j] := temp;
        };
        
        // Select winners
        let selectedWinners = Buffer.Buffer<Winner>(numWinners);
        
        for (idx in Iter.range(0, numWinners - 1)) {
            let submission = submissions[idx];
            
            let winner: Winner = {
                questId = questId;
                userId = submission.userId;
                submissionId = submission.id;
                rewardAmount = rewardPerWinner;
                paidAt = null;
                txHash = null;
            };
            
            selectedWinners.add(winner);
        };
        
        let winnersArray = Buffer.toArray(selectedWinners);
        winners.put(questId, winnersArray);
        
        #ok(winnersArray)
    };
    
    // Distribute rewards to winners
    public func distributeRewards(questId: QuestId): async Result.Result<Text, Text> {
        switch (winners.get(questId)) {
            case (?questWinners) {
                let results = Buffer.Buffer<Text>(questWinners.size());
                
                for (winner in questWinners.vals()) {
                    // Skip if already paid
                    switch (winner.paidAt) {
                        case (?_) {
                            results.add("Already paid to user: " # Principal.toText(winner.userId));
                        };
                        case null {
                            // Transfer ckBTC
                            let transferArg: TransferArg = {
                                from_subaccount = null;
                                to = {
                                    owner = winner.userId;
                                    subaccount = null;
                                };
                                amount = winner.rewardAmount;
                                fee = null;
                                memo = ?Blob.fromArray([]);
                                created_at_time = null;
                            };
                            
                            let transferResult = await ckbtcLedger.icrc1_transfer(transferArg);
                            
                            switch (transferResult) {
                                case (#Ok(blockIndex)) {
                                    // Update winner record
                                    let updatedWinner: Winner = {
                                        questId = winner.questId;
                                        userId = winner.userId;
                                        submissionId = winner.submissionId;
                                        rewardAmount = winner.rewardAmount;
                                        paidAt = ?Time.now();
                                        txHash = ?Blob.fromArray(natToBytes(blockIndex));
                                    };
                                    
                                    // Update in storage
                                    let updatedWinners = Array.map<Winner, Winner>(questWinners, func(w) {
                                        if (Principal.equal(w.userId, winner.userId)) {
                                            updatedWinner
                                        } else {
                                            w
                                        }
                                    });
                                    winners.put(questId, updatedWinners);
                                    
                                    results.add("Paid " # Nat.toText(winner.rewardAmount) # " to user: " # Principal.toText(winner.userId));
                                };
                                case (#Err(error)) {
                                    results.add("Failed to pay user " # Principal.toText(winner.userId) # ": " # errorToText(error));
                                };
                            };
                        };
                    };
                };
                
                #ok("Distribution completed. Results: " # debug_show(Buffer.toArray(results)))
            };
            case null {
                #err("No winners found for this quest")
            };
        }
    };
    
    // Get winners for a quest
    public query func getQuestWinners(questId: QuestId): async ?[Winner] {
        winners.get(questId)
    };
    
    // Get user's total winnings across all quests
    public query func getUserWinnings(userId: UserId): async {
        totalAmount: Nat;
        wins: Nat;
        winners: [Winner];
    } {
        var totalAmount: Nat = 0;
        var wins: Nat = 0;
        let userWinners = Buffer.Buffer<Winner>(0);
        
        for ((questId, questWinners) in winners.entries()) {
            for (winner in questWinners.vals()) {
                if (Principal.equal(winner.userId, userId)) {
                    totalAmount += winner.rewardAmount;
                    wins += 1;
                    userWinners.add(winner);
                };
            };
        };
        
        {
            totalAmount = totalAmount;
            wins = wins;
            winners = Buffer.toArray(userWinners);
        }
    };
    
    // Check canister balance
    public func checkBalance(): async Nat {
        let account: Account = {
            owner = Principal.fromActor(RewardCanister);
            subaccount = null;
        };
        
        await ckbtcLedger.icrc1_balance_of(account)
    };
    
    // Get all winners
    public query func getAllWinners(): async [(QuestId, [Winner])] {
        Iter.toArray(winners.entries())
    };
    
    // Helper: Convert Nat to Bytes
    private func natToBytes(n: Nat): [Nat8] {
        let bytes = Buffer.Buffer<Nat8>(8);
        var value = n;
        
        while (value > 0) {
            bytes.add(Nat8.fromNat(value % 256));
            value := value / 256;
        };
        
        Buffer.toArray(bytes)
    };
    
    // Helper: Convert transfer error to text
    private func errorToText(error: Types.TransferError): Text {
        switch (error) {
            case (#BadFee { expected_fee }) {
                "Bad fee, expected: " # Nat.toText(expected_fee)
            };
            case (#BadBurn { min_burn_amount }) {
                "Bad burn amount, minimum: " # Nat.toText(min_burn_amount)
            };
            case (#InsufficientFunds { balance }) {
                "Insufficient funds, balance: " # Nat.toText(balance)
            };
            case (#TooOld) { "Transaction too old" };
            case (#CreatedInFuture { ledger_time }) {
                "Created in future, ledger time: " # Nat.toText(Nat64.toNat(ledger_time))
            };
            case (#Duplicate { duplicate_of }) {
                "Duplicate transaction: " # Nat.toText(duplicate_of)
            };
            case (#TemporarilyUnavailable) { "Temporarily unavailable" };
            case (#GenericError { error_code; message }) {
                "Error " # Nat.toText(error_code) # ": " # message
            };
        }
    };
}