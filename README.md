# Satty - ckBTC Social Quest Giveaway DApp
# Encode BTCFi Hackathon (ICP)

A decentralized application built on the Internet Computer that allows users to earn ckBTC by completing social media quests on X (Twitter), Instagram, and TikTok.

## 🌟 Features

- **Multi-Platform Support**: Create quests for X, Instagram, and TikTok
- **Multiple Quest Types**: Like, Share, Comment, Follow, and Create Post actions
- **Fair Winner Selection**: Time-based randomized selection from verified submissions
- **Automated Rewards**: Automatic ckBTC distribution to winners
- **Multi-Canister Architecture**: Scalable design with separated concerns
- **Admin Dashboard**: Manage quests, verify submissions, and distribute rewards
- **User Profiles**: Track earnings and quest completion history
- **Leaderboard**: Showcase top earners

## 🏗️ Architecture

### Multi-Canister Design

```
┌─────────────────┐
│ Admin Canister  │ ← Orchestrates all operations
└────────┬────────┘
         │
    ┌────┼────────────────┐
    │    │                │
    ▼    ▼                ▼
┌────────────┐  ┌──────────────┐  ┌───────────────┐
│   Quest    │  │     User     │  │    Reward     │
│  Canister  │  │   Canister   │  │   Canister    │
└────────────┘  └──────────────┘  └───────┬───────┘
                                          │
                                          ▼
                                  ┌──────────────┐
                                  │ ckBTC Ledger │
                                  └──────────────┘
```

### Canister Responsibilities

1. **Quest Canister**: Manages quest creation, status, and lifecycle
2. **User Canister**: Handles user profiles and quest submissions
3. **Reward Canister**: Winner selection and ckBTC distribution
4. **Admin Canister**: Orchestrates workflows and admin operations

## 📋 Prerequisites

- [DFX SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install/) (v0.15.0+)
- [Node.js](https://nodejs.org/) (v16+)
- Internet Identity for authentication
- ckBTC for rewards

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Create project structure
mkdir satty && cd satty

# Copy all provided files to their respective directories
mkdir -p src/{quest_canister,user_canister,reward_canister,admin_canister,common}

# Place files:
# - dfx.json in root
# - types.mo in src/common/
# - main.mo files in respective canister directories
# - deploy.sh in root
```

### 2. Deploy Locally

```bash
# Make deployment script executable
chmod +x deploy.sh

# Deploy to local replica
./deploy.sh local
```

### 3. Deploy to IC Mainnet

```bash
# Deploy to mainnet
./deploy.sh ic
```

## 🎯 Usage Guide

### For Users

#### 1. Register Profile

```bash
dfx canister call user_canister registerUser \
  '("YourUsername", vec {(variant {X}, "@your_twitter")})' \
  --network ic
```

#### 2. Browse Active Quests

```bash
dfx canister call quest_canister getActiveQuests '()' --network ic
```

#### 3. Submit Quest Proof

```bash
dfx canister call user_canister submitQuest \
  '(0:nat, "https://x.com/your_proof_url")' \
  --network ic
```

#### 4. Check Submissions

```bash
dfx canister call user_canister getUserSubmissions \
  "(principal \"YOUR_PRINCIPAL\")" \
  --network ic
```

### For Admins

#### 1. Create a Quest

```bash
dfx canister call admin_canister createQuestWorkflow \
  '(
    "Follow Our X Account",
    "Follow @SattyDApp and screenshot proof",
    variant {X},
    variant {Follow},
    opt "https://x.com/SattyDApp",
    50000:nat,
    10:nat,
    1440:nat,
    opt (1000:nat)
  )' \
  --network ic
```

Parameters:
- Title: "Follow Our X Account"
- Description: Quest details
- Platform: X/Instagram/TikTok
- Action: Like/Share/Comment/Follow/CreatePost
- Target URL: Optional link to interact with
- Reward: 50000 satoshis (0.0005 ckBTC)
- Max Winners: 10
- Duration: 1440 minutes (24 hours)
- Min Followers: Optional requirement

#### 2. Verify Submissions

```bash
# Single verification
dfx canister call admin_canister verifySubmission \
  '(0:nat, true, opt "Great submission!")' \
  --network ic

# Batch verification
dfx canister call admin_canister batchVerifySubmissions \
  '(vec {
    (0:nat, true, opt "Approved");
    (1:nat, true, null);
    (2:nat, false, opt "Invalid proof")
  })' \
  --network ic
```

#### 3. Complete Quest and Distribute Rewards

```bash
dfx canister call admin_canister completeQuest '(0:nat)' --network ic
```

This automatically:
- Collects verified submissions
- Randomly selects winners based on submission time
- Distributes ckBTC rewards
- Updates user stats
- Marks quest as completed

#### 4. View Winners

```bash
dfx canister call reward_canister getQuestWinners '(0:nat)' --network ic
```

## 🔄 Workflow

### Quest Lifecycle

```
1. CREATE
   ↓
2. ACTIVE (users submit)
   ↓
3. ENDED (admin verifies)
   ↓
4. SELECTING (winners chosen)
   ↓
5. COMPLETED (rewards paid)
```

### User Journey

```
1. Register → 2. Browse Quests → 3. Complete Action
                                        ↓
                            4. Submit Proof ← 5. Get Verified
                                        ↓
                            6. Win? → 7. Receive ckBTC
```

## 💰 Funding the Reward Canister

Before distributing rewards, fund the reward canister with ckBTC:

### Mainnet

```bash
# Get reward canister principal
REWARD_PRINCIPAL=$(dfx canister id reward_canister --network ic)

# Transfer ckBTC to reward canister using your wallet
# The canister will use these funds to pay winners
```

### Local Development

For local testing, deploy a local ckBTC ledger:

```bash
# Deploy local ckBTC (see IC documentation)
# Mint test ckBTC to reward canister
```

## 📊 Analytics & Monitoring

### Check Canister Balance

```bash
dfx canister call reward_canister checkBalance '()' --network ic
```

### View Leaderboard

```bash
dfx canister call user_canister getLeaderboard '(10:nat)' --network ic
```

### Get User Winnings

```bash
dfx canister call reward_canister getUserWinnings \
  "(principal \"USER_PRINCIPAL\")" \
  --network ic
```

### System Stats

```bash
dfx canister call admin_canister getSystemStats '()' --network ic
```

## 🔐 Security Features

- **Admin Authorization**: Only authorized admins can create quests
- **Duplicate Prevention**: Users can't submit multiple times for same quest
- **Verification Required**: All submissions must be verified before reward distribution
- **Fair Randomization**: Winner selection uses timestamp-based randomization
- **Transparent Transactions**: All ckBTC transfers are recorded on-chain

## 🛠️ Development

### Testing

```bash
# Build all canisters
dfx build --all

# Run local tests
dfx canister call quest_canister getActiveQuests '()'
dfx canister call user_canister getUserProfile "(principal \"YOUR_PRINCIPAL\")"
```

### Upgrading Canisters

```bash
# Upgrade with state preservation
dfx canister install quest_canister --mode upgrade --network ic
dfx canister install user_canister --mode upgrade --network ic
dfx canister install reward_canister --mode upgrade --network ic
dfx canister install admin_canister --mode upgrade --network ic
```

## 📚 API Reference

### Quest Canister

- `createQuest()` - Create new quest
- `getQuest(questId)` - Get quest details
- `getActiveQuests()` - List active quests
- `updateQuestStatus(questId, status)` - Change quest status

### User Canister

- `registerUser(username, socialHandles)` - Register/update profile
- `submitQuest(questId, proofUrl)` - Submit quest proof
- `getUserSubmissions(userId)` - Get user's submissions
- `getQuestSubmissions(questId)` - Get quest submissions
- `getLeaderboard(limit)` - Get top earners

### Reward Canister

- `selectWinners(questId, submissions, maxWinners, reward)` - Select winners
- `distributeRewards(questId)` - Pay winners
- `getQuestWinners(questId)` - Get quest winners
- `getUserWinnings(userId)` - Get user's total winnings
- `checkBalance()` - Check canister ckBTC balance

### Admin Canister

- `initialize()` - Initialize admin
- `createQuestWorkflow()` - Create quest workflow
- `verifySubmission(submissionId, approved, note)` - Verify submission
- `completeQuest(questId)` - Complete quest and pay winners
- `batchVerifySubmissions(submissions)` - Batch verify

## 🔧 Configuration

### Quest Types

```motoko
// Social Platforms
#X | #Instagram | #TikTok

// Actions
#Like | #Share | #Comment | #Follow | #CreatePost

// Status
#Active | #Ended | #Selecting | #Completed
```

### Reward Amounts

ckBTC uses satoshis (1 BTC = 100,000,000 satoshis):
- 10,000 satoshis = 0.0001 ckBTC ≈ $10 (if BTC = $100k)
- 50,000 satoshis = 0.0005 ckBTC ≈ $50
- 100,000 satoshis = 0.001 ckBTC ≈ $100

## 🐛 Troubleshooting

### "Insufficient Funds" Error
- Ensure reward canister has enough ckBTC balance
- Check with `checkBalance()` method

### "Quest Not Found"
- Verify questId exists with `getQuest(questId)`
- Check quest status

### "Already Submitted"
- Users can only submit once per quest
- Create new quest for additional participation

### Canister Upgrade Issues
- Always use `--mode upgrade` to preserve state
- Test upgrades on local replica first

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Frontend UI development
- Enhanced verification system
- Social media API integrations
- Analytics dashboard
- Mobile app integration

## 📄 License

MIT License - See LICENSE file

## 🔗 Resources

- [Internet Computer Docs](https://internetcomputer.org/docs)
- [Motoko Documentation](https://internetcomputer.org/docs/motoko/main/getting-started/motoko-introduction)
- [ckBTC Integration Guide](https://internetcomputer.org/docs/current/developer-docs/integrations/bitcoin/)
- [DFINITY Examples](https://github.com/dfinity/examples)

## 💬 Support

- Forum: [Internet Computer Forum](https://forum.dfinity.org)
- Discord: [ICP Discord](https://discord.gg/internetcomputer)
- Twitter: [@SattyDApp](https://twitter.com/SattyDApp)

---

Built with ❤️ on the Internet Computer