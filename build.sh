#!/bin/bash

# Build script for Force Ethernet Always On Magisk Module
# This script creates a flashable ZIP for Magisk

MODULE_NAME="force-ethernet-always-on"
VERSION=$(grep "version=" module.prop | cut -d'=' -f2)
OUTPUT_ZIP="${MODULE_NAME}-v${VERSION}.zip"
TEMP_DIR="build_temp"

echo "========================================="
echo "Building Magisk Module: ${MODULE_NAME}"
echo "Version: ${VERSION}"
echo "========================================="

# Clean up old build artifacts
echo "Cleaning up old builds..."
rm -rf "$TEMP_DIR" 2>/dev/null
rm -f "${MODULE_NAME}-v"*.zip 2>/dev/null

# Create temporary build directory
echo "Creating build directory..."
mkdir -p "$TEMP_DIR"

# Copy required files to build directory
echo "Copying module files..."
cp module.prop "$TEMP_DIR/"
cp service.sh "$TEMP_DIR/"
cp customize.sh "$TEMP_DIR/"
cp uninstall.sh "$TEMP_DIR/"
cp README.md "$TEMP_DIR/"

# Create ZIP file
echo "Creating ZIP archive..."
cd "$TEMP_DIR" || exit 1
zip -r "../${OUTPUT_ZIP}" ./* -q
cd ..

# Clean up temporary directory
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

# Display results
if [ -f "$OUTPUT_ZIP" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)
    echo ""
    echo "========================================="
    echo "✓ Build successful!"
    echo "========================================="
    echo "Output: ${OUTPUT_ZIP}"
    echo "Size: ${FILE_SIZE}"
    echo ""
    echo "To install:"
    echo "1. Copy to your Android device"
    echo "2. Open Magisk Manager"
    echo "3. Install from storage"
    echo "4. Select ${OUTPUT_ZIP}"
    echo "5. Reboot"
    echo "========================================="
else
    echo ""
    echo "✗ Build failed!"
    exit 1
fi

