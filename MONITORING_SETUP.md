# Production Monitoring Setup

## UptimeRobot (FREE Plan)

1. **Sign up:** https://uptimerobot.com
2. **Create Monitor:**
   - Monitor Type: HTTP(s)
   - Friendly Name: API Sentinel Health Check
   - URL: `https://95477e84-9911-4614-bb62-52ba832fcb90-00-1a973zog8mm4f.janeway.replit.dev:8080/health`
   - Monitoring Interval: 5 minutes
   - Alert Contacts: Your email

3. **Expected Response:**
   ```json
   {"status":"healthy","timestamp":"...","version":"1.0.0","service":"api-sentinel-backend"}
   ```

## Benefits

✅ **Keeps Replit Awake**: Pings every 5 minutes prevents free tier from sleeping  
✅ **Downtime Alerts**: Email notification if API goes down  
✅ **Public Status Page**: Share uptime with customers  
✅ **FREE**: Up to 50 monitors on free plan

## Alternative: Pingdom

https://www.pingdom.com (also has free tier)

## Setup Time: 2 minutes

Once set up, your API will:
- Stay awake 24/7
- Alert you instantly if it goes down
- Show 99%+ uptime to customers
