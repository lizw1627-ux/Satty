// Common Types for Satty DApp
module {
    public type Time = Int;
    public type UserId = Principal;
    public type QuestId = Nat;
    public type SubmissionId = Nat;
    
    // Social Platform Types
    public type SocialPlatform = {
        #X;
        #Instagram;
        #TikTok;
    };
    
    // Quest Action Types
    public type QuestAction = {
        #Like;
        #Share;
        #Comment;
        #Follow;
        #CreatePost;
    };
    
    // Quest Status
    public type QuestStatus = {
        #Active;
        #Ended;
        #Selecting;
        #Completed;
    };
    
    // Quest Type
    public type Quest = {
        id: QuestId;
        title: Text;
        description: Text;
        platform: SocialPlatform;
        action: QuestAction;
        targetUrl: ?Text; // URL to interact with
        reward: Nat; // ckBTC in satoshis
        maxWinners: Nat;
        startTime: Time;
        endTime: Time;
        creator: Principal;
        status: QuestStatus;
        minFollowers: ?Nat; // Optional requirement
    };
    
    // User Profile
    public type UserProfile = {
        id: UserId;
        username: Text;
        socialHandles: [(SocialPlatform, Text)];
        totalEarned: Nat;
        questsCompleted: Nat;
        joinedAt: Time;
    };
    
    // Submission Status
    public type SubmissionStatus = {
        #Pending;
        #Verified;
        #Rejected;
        #Won;
    };
    
    // Quest Submission
    public type QuestSubmission = {
        id: SubmissionId;
        questId: QuestId;
        userId: UserId;
        proofUrl: Text; // URL to the social media post/interaction
        submittedAt: Time;
        status: SubmissionStatus;
        verificationNote: ?Text;
    };
    
    // Winner Information
    public type Winner = {
        questId: QuestId;
        userId: UserId;
        submissionId: SubmissionId;
        rewardAmount: Nat;
        paidAt: ?Time;
        txHash: ?Blob;
    };
    
    // ICRC-1 Account
    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };
    
    // Transfer Arguments
    public type TransferArg = {
        from_subaccount: ?Blob;
        to: Account;
        amount: Nat;
        fee: ?Nat;
        memo: ?Blob;
        created_at_time: ?Nat64;
    };
    
    // Transfer Result
    public type TransferResult = {
        #Ok: Nat;
        #Err: TransferError;
    };
    
    public type TransferError = {
        #BadFee: { expected_fee: Nat };
        #BadBurn: { min_burn_amount: Nat };
        #InsufficientFunds: { balance: Nat };
        #TooOld;
        #CreatedInFuture: { ledger_time: Nat64 };
        #Duplicate: { duplicate_of: Nat };
        #TemporarilyUnavailable;
        #GenericError: { error_code: Nat; message: Text };
    };
    
    // Analytics
    public type QuestAnalytics = {
        questId: QuestId;
        totalSubmissions: Nat;
        verifiedSubmissions: Nat;
        totalRewardsPaid: Nat;
        averageSubmissionTime: Time;
    };
}