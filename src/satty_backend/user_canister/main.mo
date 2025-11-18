import Types "../common/types";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";

actor UserCanister {
    type UserProfile = Types.UserProfile;
    type QuestSubmission = Types.QuestSubmission;
    type UserId = Types.UserId;
    type QuestId = Types.QuestId;
    type SubmissionId = Types.SubmissionId;
    
    // Stable storage
    stable var submissionIdCounter: Nat = 0;
    stable var stableUsers: [(UserId, UserProfile)] = [];
    stable var stableSubmissions: [(SubmissionId, QuestSubmission)] = [];
    
    // Runtime storage
    var users = HashMap.HashMap<UserId, UserProfile>(10, Principal.equal, Principal.hash);
    var submissions = HashMap.HashMap<SubmissionId, QuestSubmission>(10, Nat.equal, Nat.hash);
    var userSubmissions = HashMap.HashMap<UserId, [SubmissionId]>(10, Principal.equal, Principal.hash);
    var questSubmissions = HashMap.HashMap<QuestId, [SubmissionId]>(10, Nat.equal, Nat.hash);
    
    // Persistence
    system func preupgrade() {
        stableUsers := Iter.toArray(users.entries());
        stableSubmissions := Iter.toArray(submissions.entries());
    };
    
    system func postupgrade() {
        users := HashMap.fromIter<UserId, UserProfile>(
            stableUsers.vals(),
            stableUsers.size(),
            Principal.equal,
            Principal.hash
        );
        
        submissions := HashMap.fromIter<SubmissionId, QuestSubmission>(
            stableSubmissions.vals(),
            stableSubmissions.size(),
            Nat.equal,
            Nat.hash
        );
        
        // Rebuild indices
        for ((submissionId, submission) in stableSubmissions.vals()) {
            // User submissions index
            switch (userSubmissions.get(submission.userId)) {
                case (?existing) {
                    userSubmissions.put(submission.userId, Array.append(existing, [submissionId]));
                };
                case null {
                    userSubmissions.put(submission.userId, [submissionId]);
                };
            };
            
            // Quest submissions index
            switch (questSubmissions.get(submission.questId)) {
                case (?existing) {
                    questSubmissions.put(submission.questId, Array.append(existing, [submissionId]));
                };
                case null {
                    questSubmissions.put(submission.questId, [submissionId]);
                };
            };
        };
        
        stableUsers := [];
        stableSubmissions := [];
    };
    
    // Register or update user profile
    public shared(msg) func registerUser(
        username: Text,
        socialHandles: [(Types.SocialPlatform, Text)]
    ): async Result.Result<UserProfile, Text> {
        
        let userId = msg.caller;
        
        switch (users.get(userId)) {
            case (?existingUser) {
                // Update existing user
                let updatedUser: UserProfile = {
                    id = existingUser.id;
                    username = username;
                    socialHandles = socialHandles;
                    totalEarned = existingUser.totalEarned;
                    questsCompleted = existingUser.questsCompleted;
                    joinedAt = existingUser.joinedAt;
                };
                users.put(userId, updatedUser);
                #ok(updatedUser)
            };
            case null {
                // Create new user
                let newUser: UserProfile = {
                    id = userId;
                    username = username;
                    socialHandles = socialHandles;
                    totalEarned = 0;
                    questsCompleted = 0;
                    joinedAt = Time.now();
                };
                users.put(userId, newUser);
                #ok(newUser)
            };
        }
    };
    
    // Get user profile
    public query func getUserProfile(userId: UserId): async ?UserProfile {
        users.get(userId)
    };
    
    // Submit proof for a quest
    public shared(msg) func submitQuest(
        questId: QuestId,
        proofUrl: Text
    ): async Result.Result<SubmissionId, Text> {
        
        let userId = msg.caller;
        
        // Check if user exists
        switch (users.get(userId)) {
            case null {
                return #err("User profile not found. Please register first.");
            };
            case (?_) {};
        };
        
        // Check if user already submitted for this quest
        switch (questSubmissions.get(questId)) {
            case (?existingSubmissions) {
                for (submissionId in existingSubmissions.vals()) {
                    switch (submissions.get(submissionId)) {
                        case (?sub) {
                            if (Principal.equal(sub.userId, userId)) {
                                return #err("You have already submitted for this quest");
                            };
                        };
                        case null {};
                    };
                };
            };
            case null {};
        };
        
        let submission: QuestSubmission = {
            id = submissionIdCounter;
            questId = questId;
            userId = userId;
            proofUrl = proofUrl;
            submittedAt = Time.now();
            status = #Pending;
            verificationNote = null;
        };
        
        submissions.put(submissionIdCounter, submission);
        
        // Update user submissions index
        switch (userSubmissions.get(userId)) {
            case (?existing) {
                userSubmissions.put(userId, Array.append(existing, [submissionIdCounter]));
            };
            case null {
                userSubmissions.put(userId, [submissionIdCounter]);
            };
        };
        
        // Update quest submissions index
        switch (questSubmissions.get(questId)) {
            case (?existing) {
                questSubmissions.put(questId, Array.append(existing, [submissionIdCounter]));
            };
            case null {
                questSubmissions.put(questId, [submissionIdCounter]);
            };
        };
        
        submissionIdCounter += 1;
        
        #ok(submission.id)
    };
    
    // Get submission by ID
    public query func getSubmission(submissionId: SubmissionId): async ?QuestSubmission {
        submissions.get(submissionId)
    };
    
    // Get user's submissions
    public query func getUserSubmissions(userId: UserId): async [QuestSubmission] {
        switch (userSubmissions.get(userId)) {
            case (?submissionIds) {
                let buffer = Buffer.Buffer<QuestSubmission>(submissionIds.size());
                for (id in submissionIds.vals()) {
                    switch (submissions.get(id)) {
                        case (?submission) {
                            buffer.add(submission);
                        };
                        case null {};
                    };
                };
                Buffer.toArray(buffer)
            };
            case null { [] };
        }
    };
    
    // Get quest submissions
    public query func getQuestSubmissions(questId: QuestId): async [QuestSubmission] {
        switch (questSubmissions.get(questId)) {
            case (?submissionIds) {
                let buffer = Buffer.Buffer<QuestSubmission>(submissionIds.size());
                for (id in submissionIds.vals()) {
                    switch (submissions.get(id)) {
                        case (?submission) {
                            buffer.add(submission);
                        };
                        case null {};
                    };
                };
                Buffer.toArray(buffer)
            };
            case null { [] };
        }
    };
    
    // Verify submission (admin only - called from admin canister)
    public shared(msg) func verifySubmission(
        submissionId: SubmissionId,
        newStatus: Types.SubmissionStatus,
        note: ?Text
    ): async Result.Result<Text, Text> {
        
        switch (submissions.get(submissionId)) {
            case (?submission) {
                let updatedSubmission: QuestSubmission = {
                    id = submission.id;
                    questId = submission.questId;
                    userId = submission.userId;
                    proofUrl = submission.proofUrl;
                    submittedAt = submission.submittedAt;
                    status = newStatus;
                    verificationNote = note;
                };
                
                submissions.put(submissionId, updatedSubmission);
                #ok("Submission verified successfully")
            };
            case null {
                #err("Submission not found")
            };
        }
    };
    
    // Update user stats after winning
    public func updateUserStats(userId: UserId, rewardAmount: Nat): async Result.Result<Text, Text> {
        switch (users.get(userId)) {
            case (?user) {
                let updatedUser: UserProfile = {
                    id = user.id;
                    username = user.username;
                    socialHandles = user.socialHandles;
                    totalEarned = user.totalEarned + rewardAmount;
                    questsCompleted = user.questsCompleted + 1;
                    joinedAt = user.joinedAt;
                };
                
                users.put(userId, updatedUser);
                #ok("User stats updated")
            };
            case null {
                #err("User not found")
            };
        }
    };
    
    // Get leaderboard
    public query func getLeaderboard(limit: Nat): async [UserProfile] {
        let allUsers = Iter.toArray(users.vals());
        
        // Sort by totalEarned (descending)
        let sorted = Array.sort<UserProfile>(allUsers, func(a, b) {
            if (a.totalEarned > b.totalEarned) { #less }
            else if (a.totalEarned < b.totalEarned) { #greater }
            else { #equal }
        });
        
        let resultSize = Nat.min(limit, sorted.size());
        Array.tabulate<UserProfile>(resultSize, func(i) {
            sorted[i]
        })
    };
    
    // Get verified submissions for a quest (for winner selection)
    public query func getVerifiedSubmissions(questId: QuestId): async [QuestSubmission] {
        switch (questSubmissions.get(questId)) {
            case (?submissionIds) {
                let buffer = Buffer.Buffer<QuestSubmission>(0);
                for (id in submissionIds.vals()) {
                    switch (submissions.get(id)) {
                        case (?submission) {
                            if (submission.status == #Verified) {
                                buffer.add(submission);
                            };
                        };
                        case null {};
                    };
                };
                Buffer.toArray(buffer)
            };
            case null { [] };
        }
    };
}