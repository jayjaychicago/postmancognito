#!/bin/bash

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Install dependencies based on the system
install_dependencies() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macOS detected"
        if ! check_command "brew"; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        echo "Installing dependencies with Homebrew..."
        brew install jq awscli
    else
        echo "Linux detected"
        if check_command "apt-get"; then
            echo "Installing dependencies with apt..."
            sudo apt-get update
            sudo apt-get install -y jq awscli
        elif check_command "yum"; then
            echo "Installing dependencies with yum..."
            sudo yum install -y jq aws-cli
        else
            echo "Error: Could not find apt-get or yum. Please install jq and awscli manually."
            exit 1
        fi
    fi
}

# Check for required tools
echo "Checking required dependencies..."
MISSING_DEPS=0

if ! check_command "aws"; then
    echo "aws CLI is missing"
    MISSING_DEPS=1
fi

if ! check_command "jq"; then
    echo "jq is missing"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    read -p "Would you like to install missing dependencies? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_dependencies
    else
        echo "Please install the missing dependencies manually and run the script again."
        exit 1
    fi
fi

# Verify AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Set variables
POOL_NAME="MyCognitoPool"
DOMAIN_PREFIX="my-api-domain-$(date +%s)"
APP_CLIENT_NAME="MyApiClient"
TEST_USERNAME="testuser@example.com"
TEST_PASSWORD="TestPassword123!"
REGION="us-east-2"
OUTPUT_FILE="postman_collection.json"

# Create Cognito User Pool
echo "Creating Cognito User Pool..."
POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name $POOL_NAME \
    --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":true}}' \
    --schema '[{"Name":"email","Required":true,"Mutable":true}]' \
    --auto-verified-attributes email \
    --query 'UserPool.Id' \
    --output text)

echo "User Pool ID: $POOL_ID"

# Create Domain
echo "Creating Cognito Domain..."
aws cognito-idp create-user-pool-domain \
    --domain $DOMAIN_PREFIX \
    --user-pool-id $POOL_ID

# Create App Client
echo "Creating App Client..."
CLIENT_INFO=$(aws cognito-idp create-user-pool-client \
    --user-pool-id $POOL_ID \
    --client-name $APP_CLIENT_NAME \
    --generate-secret \
    --allowed-o-auth-flows "code" "implicit" \
    --allowed-o-auth-scopes "email" "openid" \
    --allowed-o-auth-flows-user-pool-client \
    --supported-identity-providers COGNITO \
    --callback-urls '["https://oauth.pstmn.io/v1/browser-callback"]' \
    --logout-urls '["http://localhost"]' \
    --output json)

CLIENT_ID=$(echo $CLIENT_INFO | jq -r '.UserPoolClient.ClientId')
CLIENT_SECRET=$(echo $CLIENT_INFO | jq -r '.UserPoolClient.ClientSecret')

DOMAIN="https://${DOMAIN_PREFIX}.auth.${REGION}.amazoncognito.com"

# Generate Postman Collection with the format that works
cat > $OUTPUT_FILE << EOF
{
    "info": {
        "name": "Cognito Protected API",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "item": [
        {
            "name": "Get Cat Fact",
            "request": {
                "auth": {
                    "type": "oauth2",
                    "oauth2": [
                        {
                            "key": "grant_type",
                            "value": "authorization_code",
                            "type": "string"
                        },
                        {
                            "key": "redirect_uri",
                            "value": "https://oauth.pstmn.io/v1/browser-callback",
                            "type": "string"
                        },
                        {
                            "key": "authUrl",
                            "value": "${DOMAIN}/oauth2/authorize",
                            "type": "string"
                        },
                        {
                            "key": "accessTokenUrl",
                            "value": "${DOMAIN}/oauth2/token",
                            "type": "string"
                        },
                        {
                            "key": "clientId",
                            "value": "${CLIENT_ID}",
                            "type": "string"
                        },
                        {
                            "key": "clientSecret",
                            "value": "${CLIENT_SECRET}",
                            "type": "string"
                        },
                        {
                            "key": "scope",
                            "value": "email openid",
                            "type": "string"
                        },
                        {
                            "key": "client_authentication",
                            "value": "header",
                            "type": "string"
                        },
                        {
                            "key": "addTokenTo",
                            "value": "header",
                            "type": "string"
                        },
                        {
                            "key": "state",
                            "value": "",
                            "type": "string"
                        },
                        {
                            "key": "useBrowser",
                            "value": true,
                            "type": "boolean"
                        }
                    ]
                },
                "method": "GET",
                "header": [],
                "url": {
                    "raw": "https://catfact.ninja/fact",
                    "protocol": "https",
                    "host": [
                        "catfact",
                        "ninja"
                    ],
                    "path": [
                        "fact"
                    ]
                }
            },
            "response": []
        }
    ]
}
EOF

# Create test user
echo "Creating test user..."
aws cognito-idp admin-create-user \
    --user-pool-id $POOL_ID \
    --username $TEST_USERNAME \
    --temporary-password $TEST_PASSWORD \
    --message-action SUPPRESS

# Set permanent password for test user
aws cognito-idp admin-set-user-password \
    --user-pool-id $POOL_ID \
    --username $TEST_USERNAME \
    --password $TEST_PASSWORD \
    --permanent

echo ""
echo "Setup complete! Here are your OAuth 2.0 settings:"
echo ""
echo "Cognito Configuration:"
echo "---------------------"
echo "User Pool ID: $POOL_ID"
echo "Domain: $DOMAIN"
echo "App Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo ""
echo "Test User Credentials:"
echo "---------------------"
echo "Username: $TEST_USERNAME"
echo "Password: $TEST_PASSWORD"
echo ""
echo "Instructions:"
echo "1. Import the generated $OUTPUT_FILE into Postman"
echo "2. The OAuth2 settings will be pre-filled automatically"
echo "3. Click 'Get New Access Token' in the Authorization tab"
echo "4. Log in with the test user credentials when prompted"
echo "5. Click 'Use Token' after obtaining it"