# Get the OpenChat public key - the OC website must be running on localhost:5001
OC_PUBLIC_KEY=$(curl -s http://localhost:5001/public-key)

if [ $? -ne 0 ]; then
    echo "OpenChat is not running on http://localhost:5001."
    exit 1
fi

# Deploy the fractal_sortition_oc_bot_backend
dfx deploy fractal_sortition_oc_bot_backend --argument "(\"$OC_PUBLIC_KEY\")" || exit 1

# Get the canister ID
CANISTER_ID=$(dfx canister id fractal_sortition_oc_bot_backend) || exit 1

echo ""
echo "Principal: $CANISTER_ID"
echo "Endpoint: http://$CANISTER_ID.raw.localhost:8080"
echo ""