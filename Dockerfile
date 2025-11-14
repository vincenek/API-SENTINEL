FROM dart:stable

WORKDIR /app

# Copy backend pubspec files
COPY backend/pubspec.yaml ./
COPY backend/pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy backend source code
COPY backend/bin ./bin
COPY backend/lib ./lib

# Expose port
EXPOSE 8080

# Set environment variable
ENV PORT=8080

# Run the server
CMD ["dart", "run", "bin/server.dart"]
