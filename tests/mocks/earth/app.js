const express = require('express');
const app = express();

const VALID_API_KEY = 'valid-api-key';
const VALID_ACCESS_TOKEN = 'valid-token';

app.get('/the-meaning-of-life', (req, res) => {
  const apiKey = req.header('x-api-key');
  const authHeader = req.header('Authorization');
  const token = authHeader?.replace('Bearer ', '');

  const validApiKey = apiKey === VALID_API_KEY;
  const validToken = token === VALID_ACCESS_TOKEN;

  if (!validApiKey && !validToken) {
    return res.status(401).json({ error: 'Invalid or missing API key and access token: ' + apiKey });
  }

  return res.json({ meaning: "42" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Mock API server running at http://localhost:${PORT}`);
});