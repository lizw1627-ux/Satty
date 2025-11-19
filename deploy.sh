#!/bin/bash

# Satty ckBTC Giveaway DApp Deployment Script

set -e

echo "🚀 Starting Satty DApp Deployment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if dfx is installed
if ! command -v dfx &> /dev/null; then
    echo -e "${RED}Error: dfx not found. Please install dfx first.${NC}"
    exit 1
fi

# Get network (local or ic)
NETWORK=${1:-local}

echo -e "${BLUE}Deploying to: ${NETWORK}${NC}"

# Start local replica if deploying locally
if [ "$NETWORK" = "local" ]; then
    echo -e "${BLUE}Starting local replica...${NC}"
    dfx start --background --clean
    sleep 5
fi

# Get deployer identity
DEPLOYER=$(dfx identity get-principal)
echo -e "${GREEN}Deployer Principal: ${DEPLOYER}${NC}"

# Deploy canisters in order
echo -e "${BLUE}Step 1: Deploying User Canister...${NC}"
dfx deploy user_canister --network $NETWORK
USER_CANISTER=$(dfx canister id user_canister --network $NETWORK)
echo -e "${GREEN}✓ User Canister deployed: ${USER_CANISTER}${NC}"

echo -e "${BLUE}Step 2: Deploying Quest Canister...${NC}"
dfx deploy quest_canister --network $NETWORK
QUEST_CANISTER=$(dfx canister id quest_canister --network $NETWORK)
echo -e "${GREEN}✓ Quest Canister deployed: ${QUEST_CANISTER}${NC}"

echo -e "${BLUE}Step 3: Deploying Reward Canister...${NC}"
dfx deploy reward_canister --network $NETWORK
REWARD_CANISTER=$(dfx canister id reward_canister --network $NETWORK)
echo -e "${GREEN}✓ Reward Canister deployed: ${REWARD_CANISTER}${NC}"

echo -e "${BLUE}Step 4: Deploying Admin Canister...${NC}"
dfx deploy admin_canister --network $NETWORK
ADMIN_CANISTER=$(dfx canister id admin_canister --network $NETWORK)
echo -e "${GREEN}✓ Admin Canister deployed: ${ADMIN_CANISTER}${NC}"

# Initialize admin canister
echo -e "${BLUE}Step 5: Initializing Admin Canister...${NC}"
dfx canister call admin_canister initialize --network $NETWORK
echo -e "${GREEN}✓ Admin initialized with deployer principal${NC}"

# Set canister references
echo -e "${BLUE}Step 6: Configuring Canister References...${NC}"
dfx canister call admin_canister setCanisterIds \
    "(\"$QUEST_CANISTER\", \"$USER_CANISTER\", \"$REWARD_CANISTER\")" \
    --network $NETWORK
echo -e "${GREEN}✓ Canister references configured${NC}"

# Add deployer as admin to quest canister
echo -e "${BLUE}Step 7: Adding Admin to Quest Canister...${NC}"
dfx canister call quest_canister addAdmin "(principal \"$DEPLOYER\")" --network $NETWORK
echo -e "${GREEN}✓ Admin added to Quest Canister${NC}"

# Display deployment summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Satty DApp Deployment Complete!     ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Canister IDs:${NC}"
echo -e "Quest Canister:  ${GREEN}$QUEST_CANISTER${NC}"
echo -e "User Canister:   ${GREEN}$USER_CANISTER${NC}"
echo -e "Reward Canister: ${GREEN}$REWARD_CANISTER${NC}"
echo -e "Admin Canister:  ${GREEN}$ADMIN_CANISTER${NC}"
echo ""
echo -e "${BLUE}Admin Principal: ${GREEN}$DEPLOYER${NC}"
echo ""

# Save canister IDs to file
cat > canister_ids.txt << EOF
QUEST_CANISTER=$QUEST_CANISTER
USER_CANISTER=$USER_CANISTER
REWARD_CANISTER=$REWARD_CANISTER
ADMIN_CANISTER=$ADMIN_CANISTER
DEPLOYER=$DEPLOYER
NETWORK=$NETWORK
EOF

echo -e "${GREEN}✓ Canister IDs saved to canister_ids.txt${NC}"

# If local deployment, fund the reward canister with test ckBTC
if [ "$NETWORK" = "local" ]; then
    echo ""
    echo -e "${BLUE}Setting up local ckBTC for testing...${NC}"
    echo -e "${RED}Note: For local testing, you'll need to manually deploy and configure ckBTC ledger${NC}"
    echo -e "${RED}Refer to: https://internetcomputer.org/docs/references/samples/motoko/ic-pos/${NC}"
fi

echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "1. Register a user: ${BLUE}dfx canister call user_canister registerUser '(\"username\", vec {(variant {X}, \"@twitter_handle\")})' --network $NETWORK${NC}"
echo -e "2. Create a quest: ${BLUE}dfx canister call admin_canister createQuestWorkflow '(\"Quest Title\", \"Description\", variant {X}, variant {Like}, opt \"https://x.com/post\", 10000:nat, 3:nat, 60:nat, null)' --network $NETWORK${NC}"
echo -e "3. Submit a quest: ${BLUE}dfx canister call user_canister submitQuest '(0:nat, \"https://x.com/proof\")' --network $NETWORK${NC}"
echo ""
echo -e "${GREEN}🎉 Happy building with Satty!${NC}"