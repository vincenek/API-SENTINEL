FROM dart:stable

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./

# Install dependencies
RUN dart pub get

# Copy the rest of the application
COPY . .

# Expose port
EXPOSE 8080

# Set environment variable
ENV PORT=8080

# Run the server
CMD ["dart", "run", "bin/server.dart"]
