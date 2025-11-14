FROM dart:stable

WORKDIR /app/backend

# Copy pubspec file
COPY backend/pubspec.yaml ./

# Install dependencies
RUN dart pub get

# Copy the rest of the application
COPY backend/ ./

# Expose port
EXPOSE 8080

# Set environment variable
ENV PORT=8080

# Run the server
CMD ["dart", "run", "bin/server.dart"]
