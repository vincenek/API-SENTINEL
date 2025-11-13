#!/usr/bin/env bash
# Quick Start Script for API Sentinel Development

echo "🚀 API Sentinel - Quick Start"
echo "================================"
echo ""

# Check Flutter installation
echo "📋 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter is installed"
flutter --version
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Run analyzer
echo "🔍 Running code analysis..."
flutter analyze

if [ $? -ne 0 ]; then
    echo "⚠️  Code analysis found issues (non-critical)"
else
    echo "✅ Code analysis passed"
fi
echo ""

# Run the demo app
echo "🎯 Ready to run!"
echo ""
echo "To run the demo app:"
echo "  flutter run"
echo ""
echo "To run on specific platform:"
echo "  flutter run -d chrome    # Web"
echo "  flutter run -d windows   # Windows"
echo "  flutter run -d macos     # macOS"
echo ""
echo "To build for production:"
echo "  flutter build web"
echo "  flutter build windows"
echo ""
echo "✨ Setup complete! Happy coding!"
