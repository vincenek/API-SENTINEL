const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());

// Configuration
const PORT = 3001;
const API_SENTINEL_KEY = process.env.API_SENTINEL_KEY || 'sk_your_api_key_here';
const API_SENTINEL_ENDPOINT = 'http://localhost:8080/api/v1/analytics/events';

// Simulate Stripe payment
async function chargeStripe(amount, currency) {
  await new Promise(resolve => setTimeout(resolve, 200));
  
  // 30% failure rate for demo
  if (Math.random() < 0.3) {
    throw new Error('Stripe gateway timeout');
  }
  
  return {
    transactionId: `stripe_txn_${Date.now()}`,
    amount,
    currency,
    gateway: 'stripe'
  };
}

// Simulate Square payment
async function chargeSquare(amount, currency) {
  await new Promise(resolve => setTimeout(resolve, 250));
  
  // 10% failure rate
  if (Math.random() < 0.1) {
    throw new Error('Square processing error');
  }
  
  return {
    transactionId: `square_txn_${Date.now()}`,
    amount,
    currency,
    gateway: 'square'
  };
}

// Report failover event to API Sentinel
async function reportFailoverEvent(eventData) {
  try {
    console.log('📊 Reporting to API Sentinel:', eventData);
    
    await axios.post(API_SENTINEL_ENDPOINT, eventData, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_SENTINEL_KEY}`
      }
    });
    
    console.log('✅ Event reported successfully');
  } catch (error) {
    console.warn('⚠️  Failed to report to API Sentinel:', error.message);
  }
}

// Payment endpoint with failover
app.post('/api/payment/charge', async (req, res) => {
  const { amount, currency = 'USD', customerId } = req.body;
  
  if (!amount) {
    return res.status(400).json({ error: 'Amount is required' });
  }
  
  console.log(`💳 Processing payment: $${amount} ${currency}`);
  const startTime = Date.now();
  
  try {
    // Try primary gateway (Stripe)
    const result = await chargeStripe(amount, currency);
    console.log('✅ Stripe charge successful:', result.transactionId);
    
    return res.json({
      success: true,
      gateway: 'stripe',
      transactionId: result.transactionId,
      amount
    });
  } catch (stripeError) {
    console.log('❌ Stripe failed:', stripeError.message);
    
    try {
      // Failover to secondary gateway (Square)
      const result = await chargeSquare(amount, currency);
      const recoveryTime = Date.now() - startTime;
      
      console.log('✅ Square charge successful:', result.transactionId);
      console.log(`⚡ Recovery time: ${recoveryTime}ms`);
      
      // Report to API Sentinel
      await reportFailoverEvent({
        timestamp: new Date().toISOString(),
        primaryGateway: 'stripe',
        secondaryGateway: 'square',
        errorType: stripeError.message.includes('timeout') ? 'network_timeout' : 'gateway_error',
        amount,
        currency,
        success: true,
        recoveryTimeMs: recoveryTime
      });
      
      return res.json({
        success: true,
        gateway: 'square',
        failedGateway: 'stripe',
        transactionId: result.transactionId,
        amount,
        recoveryTimeMs: recoveryTime
      });
    } catch (squareError) {
      console.log('❌ Square also failed:', squareError.message);
      
      // Report failed failover
      await reportFailoverEvent({
        timestamp: new Date().toISOString(),
        primaryGateway: 'stripe',
        secondaryGateway: 'square',
        errorType: 'complete_failure',
        amount,
        currency,
        success: false,
        recoveryTimeMs: Date.now() - startTime
      });
      
      return res.status(500).json({
        success: false,
        error: 'All payment gateways failed'
      });
    }
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

app.listen(PORT, () => {
  console.log(`✅ Payment server running on http://localhost:${PORT}`);
  console.log(`📊 API Sentinel integration enabled`);
});
