import Types "../common/types";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

actor QuestCanister {
    type Quest = Types.Quest;
    type QuestId = Types.QuestId;
    type QuestStatus = Types.QuestStatus;
    
    // Stable storage for upgrades
    stable var questIdCounter: Nat = 0;
    stable var stableQuests: [(QuestId, Quest)] = [];
    
    // Runtime storage
    var quests = HashMap.HashMap<QuestId, Quest>(10, Nat.equal, Nat.hash);
    
    // Admins who can create quests
    stable var admins: [Principal] = [];
    
    // Initialize from stable storage
    system func preupgrade() {
        stableQuests := Iter.toArray(quests.entries());
    };
    
    system func postupgrade() {
        quests := HashMap.fromIter<QuestId, Quest>(
            stableQuests.vals(),
            stableQuests.size(),
            Nat.equal,
            Nat.hash
        );
        stableQuests := [];
    };
    
    // Check if caller is admin
    private func isAdmin(caller: Principal): Bool {
        for (admin in admins.vals()) {
            if (Principal.equal(admin, caller)) {
                return true;
            };
        };
        false
    };
    
    // Add admin (owner only)
    public shared(msg) func addAdmin(newAdmin: Principal): async Result.Result<Text, Text> {
        if (admins.size() == 0 or isAdmin(msg.caller)) {
            admins := Array.append(admins, [newAdmin]);
            #ok("Admin added successfully")
        } else {
            #err("Unauthorized: Only admins can add new admins")
        }
    };
    
    // Create a new quest
    public shared(msg) func createQuest(
        title: Text,
        description: Text,
        platform: Types.SocialPlatform,
        action: Types.QuestAction,
        targetUrl: ?Text,
        reward: Nat,
        maxWinners: Nat,
        durationMinutes: Nat,
        minFollowers: ?Nat
    ): async Result.Result<QuestId, Text> {
        
        if (not isAdmin(msg.caller)) {
            return #err("Unauthorized: Only admins can create quests");
        };
        
        let now = Time.now();
        let endTime = now + (durationMinutes * 60_000_000_000); // Convert to nanoseconds
        
        let quest: Quest = {
            id = questIdCounter;
            title = title;
            description = description;
            platform = platform;
            action = action;
            targetUrl = targetUrl;
            reward = reward;
            maxWinners = maxWinners;
            startTime = now;
            endTime = endTime;
            creator = msg.caller;
            status = #Active;
            minFollowers = minFollowers;
        };
        
        quests.put(questIdCounter, quest);
        questIdCounter += 1;
        
        #ok(quest.id)
    };
    
    // Get quest by ID
    public query func getQuest(questId: QuestId): async ?Quest {
        quests.get(questId)
    };
    
    // Get all active quests
    public query func getActiveQuests(): async [Quest] {
        let now = Time.now();
        let buffer = Buffer.Buffer<Quest>(0);
        
        for ((id, quest) in quests.entries()) {
            if (quest.status == #Active and quest.endTime > now) {
                buffer.add(quest);
            };
        };
        
        Buffer.toArray(buffer)
    };
    
    // Get all quests (paginated)
    public query func getAllQuests(offset: Nat, limit: Nat): async {
        quests: [Quest];
        total: Nat;
    } {
        let allQuests = Iter.toArray(quests.vals());
        let total = allQuests.size();
        
        let end = Nat.min(offset + limit, total);
        let slice = if (offset < total) {
            Array.tabulate<Quest>(end - offset, func(i) {
                allQuests[offset + i]
            })
        } else {
            []
        };
        
        {
            quests = slice;
            total = total;
        }
    };
    
    // Update quest status
    public shared(msg) func updateQuestStatus(
        questId: QuestId,
        newStatus: QuestStatus
    ): async Result.Result<Text, Text> {
        
        if (not isAdmin(msg.caller)) {
            return #err("Unauthorized");
        };
        
        switch (quests.get(questId)) {
            case (?quest) {
                let updatedQuest: Quest = {
                    id = quest.id;
                    title = quest.title;
                    description = quest.description;
                    platform = quest.platform;
                    action = quest.action;
                    targetUrl = quest.targetUrl;
                    reward = quest.reward;
                    maxWinners = quest.maxWinners;
                    startTime = quest.startTime;
                    endTime = quest.endTime;
                    creator = quest.creator;
                    status = newStatus;
                    minFollowers = quest.minFollowers;
                };
                
                quests.put(questId, updatedQuest);
                #ok("Quest status updated successfully")
            };
            case null {
                #err("Quest not found")
            };
        }
    };
    
    // Auto-end expired quests
    public func checkExpiredQuests(): async () {
        let now = Time.now();
        
        for ((id, quest) in quests.entries()) {
            if (quest.status == #Active and quest.endTime <= now) {
                ignore await updateQuestStatus(id, #Ended);
            };
        };
    };
    
    // Get quests by platform
    public query func getQuestsByPlatform(platform: Types.SocialPlatform): async [Quest] {
        let buffer = Buffer.Buffer<Quest>(0);
        
        for ((id, quest) in quests.entries()) {
            if (quest.platform == platform and quest.status == #Active) {
                buffer.add(quest);
            };
        };
        
        Buffer.toArray(buffer)
    };
    
    // Get quest statistics
    public query func getQuestStats(questId: QuestId): async ?{
        quest: Quest;
        isActive: Bool;
        timeRemaining: Int;
    } {
        switch (quests.get(questId)) {
            case (?quest) {
                let now = Time.now();
                ?{
                    quest = quest;
                    isActive = quest.status == #Active and quest.endTime > now;
                    timeRemaining = quest.endTime - now;
                }
            };
            case null { null };
        }
    };
}