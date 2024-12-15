// Import fetch from node-fetch
import fetch from 'node-fetch';

async function getTokens(clientId, clientSecret, username, password, tokenUrl) {
  const params = new URLSearchParams();
  params.append('grant_type', 'password');
  params.append('client_id', clientId);
  params.append('client_secret', clientSecret);  // Include if required and safe to do so
  params.append('username', username);
  params.append('password', password);
  params.append('scope', 'openid');  // Adjust scopes as needed

  try {
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: params
    });

    const data = await response.json();
    console.log('Tokens:', data);
    return data;
  } catch (error) {
    console.error('Failed to fetch tokens:', error);
    throw error;
  }
}

// Replace placeholders with actual values
const clientId = '7s24sfbIfv2lmjaqlsntq2avs';
const clientSecret = 'your_client_secret'; // Be cautious with the client secret
const username = 'your_username';
const password = 'your_password';
const tokenUrl = 'https://your_cognito_domain.auth.eu-west-1.amazoncognito.com/oauth2/token';

// Call the function with actual values
getTokens(clientId, clientSecret, username, password, tokenUrl)
  .then(tokens => console.log('Fetched Tokens:', tokens))
  .catch(err => console.error('Error:', err));
