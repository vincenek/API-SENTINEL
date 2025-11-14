# API Sentinel Backend

## Quick Deploy to Production

### Option 1: Railway (Recommended - Easiest)

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login to Railway
railway login

# Deploy from this directory
railway init
railway up
```

You'll get a URL like: `https://apisentinel-production.up.railway.app`

### Option 2: Fly.io

```bash
# Install flyctl
# Windows PowerShell:
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"

# Sign up
flyctl auth signup

# Deploy
flyctl launch

# Set secrets
flyctl secrets set JWT_SECRET="your-production-secret-key-here"
```

### Option 3: Docker (Self-Hosted)

```bash
# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### Option 4: Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy apisentinel \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars JWT_SECRET="your-secret-key"
```

## Environment Variables

Required:
- `JWT_SECRET` - Secret key for JWT token generation (change from default!)

Optional:
- `PORT` - Port to run on (default: 8080)
- `DATABASE_PATH` - Path to SQLite database (default: ./data/api_sentinel.db)

## After Deployment

1. **Test health endpoint:**
   ```bash
   curl https://your-deployed-url.com/health
   ```

2. **Create first customer:**
   ```bash
   curl -X POST https://your-deployed-url.com/api/v1/customers/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "admin@yourcompany.com",
       "password": "SecurePassword123!",
       "companyName": "Your Company"
     }'
   ```

3. **Update SDK configuration** in your Flutter apps to point to deployed URL

## Production Checklist

- [ ] Change JWT_SECRET from default value
- [ ] Set up database backups
- [ ] Configure monitoring (Sentry, DataDog)
- [ ] Set up uptime monitoring
- [ ] Enable HTTPS (automatic on Railway/Fly.io/Cloud Run)
- [ ] Configure rate limiting if needed
- [ ] Set up error alerting

## Local Development

```bash
# Run locally
dart run bin/server.dart

# Backend runs on http://localhost:8080
```

## Support

- Issues: GitHub Issues
- Email: support@apisentinel.com
- Docs: /api/v1/docs endpoint
