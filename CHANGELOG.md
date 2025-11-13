# Changelog

All notable changes to the API Sentinel Flutter SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-12

### Added
- Initial production release
- Automatic payment gateway failover
- Real-time analytics tracking
- Secure API key storage using flutter_secure_storage
- Comprehensive error handling with custom exceptions
- Retry policy with exponential backoff
- Circuit breaker pattern for failure prevention
- Client-side rate limiting
- Offline request queue with persistence
- Request/response validation
- Environment configuration (dev/staging/prod)
- Pre-built UI components:
  - LoadingOverlay
  - PaymentStatusWidget
  - FailoverIndicatorBadge
  - GatewayStatusIndicator
- Comprehensive unit tests (>80% coverage)
- Full API documentation

### Features
- ✅ Multi-gateway failover support
- ✅ Sub-100ms failover detection
- ✅ Recovery time metrics
- ✅ Customizable retry policies
- ✅ Production-ready error handling
- ✅ Offline-first architecture
- ✅ Rate limiting protection
- ✅ Debug logging
- ✅ Analytics integration

### Security
- API keys stored securely
- HTTPS-only communication
- Input validation and sanitization
- No sensitive data in logs

### Performance
- < 500ms initialization time
- < 100ms failover detection
- Efficient memory usage
- Background queue processing

## [0.1.0] - 2025-11-12 [YANKED]

### Added
- Initial demo implementation
- Basic failover logic
- Simple UI components

---

For migration guides and detailed release notes, visit:
https://docs.apisentinel.com/changelog
