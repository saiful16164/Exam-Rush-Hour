#!/bin/bash

# Download Flutter SDK
echo "Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable

# Add flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Check Flutter version and dependencies
flutter doctor -v

# Enable web support (just in case)
flutter config --enable-web

# Get project dependencies
echo "Getting dependencies..."
flutter pub get

# Build the web app
echo "Building the web app..."
flutter build web --release
