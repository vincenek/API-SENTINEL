# API Sentinel - Reference Implementation Guide

This directory contains complete reference implementations showing how to integrate API Sentinel into your payment processing systems.

## 📁 Implementations Included

1. **Dart/Flutter Backend** - Complete server-side implementation
2. **Node.js/Express** - JavaScript/TypeScript backend integration  
3. **Python/FastAPI** - Python backend integration

## 🚀 Quick Start

Each implementation demonstrates:

- ✅ Payment processor abstraction
- ✅ Primary/secondary gateway failover logic
- ✅ Integration with API Sentinel SDK
- ✅ Error handling and retry strategies
- ✅ Transaction logging and analytics

## 📖 Implementation Details

### 1. Dart Backend (`dart_backend_example/`)

A complete Dart server using Shelf framework with:
- Stripe and PayPal gateway integration
- API Sentinel SDK for failover tracking
- RESTful payment endpoints
- Environment-based configuration

**Run:**
```bash
cd dart_backend_example
dart pub get
dart run bin/server.dart
```

### 2. Node.js Backend (`nodejs_backend_example/`)

Express.js server with TypeScript support:
- Stripe and Square integration
- API Sentinel REST API calls
- Express middleware for payment processing
- Comprehensive error handling

**Run:**
```bash
cd nodejs_backend_example
npm install
npm run dev
```

### 3. Python Backend (`python_backend_example/`)

FastAPI implementation with:
- Async payment processing
- Multiple gateway support (Stripe, PayPal, Square)
- API Sentinel analytics integration
- Pydantic models for type safety

**Run:**
```bash
cd python_backend_example
pip install -r requirements.txt
uvicorn main:app --reload
```

## 🔑 Configuration

Each example requires:

1. **API Sentinel API Key** - Get from dashboard
2. **Payment Gateway Credentials** - Stripe, PayPal, etc.
3. **Environment Variables** - See `.env.example` in each directory

## 📊 Features Demonstrated

### Payment Flow
```
Customer Request → Primary Gateway (Stripe)
                    ↓ (fails)
                  API Sentinel Records Event
                    ↓
                Secondary Gateway (PayPal)
                    ↓ (succeeds)
                  Response to Customer
```

### Analytics Integration
All examples show how to:
- Track successful failovers
- Record recovery time
- Calculate saved revenue
- Send events to API Sentinel backend

## 🧪 Testing

Each implementation includes:
- Unit tests for gateway integration
- Integration tests for failover logic
- Example API requests in `.http` files

## 📚 Additional Resources

- [API Sentinel Documentation](../README.md)
- [Flutter SDK Documentation](../lib/README.md)
- [Backend API Reference](../backend/README.md)
- [Dashboard User Guide](../dashboard/README.md)

## 💡 Best Practices

1. **Always use environment variables** for credentials
2. **Implement proper error handling** at each gateway
3. **Set appropriate timeouts** (recommended: 5-10 seconds)
4. **Log all failover events** for analytics
5. **Test failover scenarios** in staging environment
6. **Monitor gateway health** regularly

## 🆘 Support

For issues or questions:
- Check the main [README](../README.md)
- Review [API documentation](../backend/README.md)
- Contact support at support@apisentinel.example
