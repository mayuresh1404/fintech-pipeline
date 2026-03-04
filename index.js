const express = require('express');
const app = express();
app.use(express.json());

// Updated health route
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    version: process.env.APP_VERSION || 'v1',
    build: 'stable'
  });
});

// NEW route added in v2
app.get('/market-status', (req, res) => {
  const now = new Date();
  const hours = now.getUTCHours() + 5.5; // IST
  const minutes = now.getUTCMinutes();
  const timeInMinutes = (hours % 24) * 60 + minutes;
  const marketOpen = 9 * 60 + 15;   // 9:15 AM
  const marketClose = 15 * 60 + 30; // 3:30 PM

  res.json({
    isOpen: timeInMinutes >= marketOpen && timeInMinutes <= marketClose,
    message: timeInMinutes >= marketOpen && timeInMinutes <= marketClose 
      ? '🟢 Market is OPEN' 
      : '🔴 Market is CLOSED'
  });
});

app.post('/order', (req, res) => {
  const { stock, qty, type } = req.body;
  if (!stock || !qty || !type) {
    return res.status(400).json({ error: 'Missing fields: stock, qty, type' });
  }
  res.json({
    orderId: `ORD-${Date.now()}`,
    stock, qty, type,
    status: 'PLACED',
    timestamp: new Date().toISOString()
  });
});

app.listen(3000, () => console.log(`Trade API v2 running on port 3000`));