FROM dart:stable

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./
COPY pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY bin ./bin
COPY lib ./lib

# Expose port
EXPOSE 8080

# Set environment variable
ENV PORT=8080

# Run the server
CMD ["dart", "run", "bin/server.dart"]
