# Deploy the canister
icp deploy fractal_sortition_oc_bot_backend --environment ic || exit 1

# Get the canister ID
CANISTER_ID=$(icp canister settings show -e ic fractal_sortition_oc_bot_backend -p --json | jq -r '.id')

# Show bot registration data
echo ""
echo "Principal: $CANISTER_ID"
echo "Endpoint: https://$CANISTER_ID.raw.icp0.io"