# Build script for Force Ethernet Always On Magisk Module
# PowerShell version for Windows

$MODULE_NAME = "force-ethernet-always-on"
$VERSION = (Get-Content module.prop | Select-String "version=").ToString().Split("=")[1]
$OUTPUT_ZIP = "$MODULE_NAME-v$VERSION.zip"
$TEMP_DIR = "build_temp"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Building Magisk Module: $MODULE_NAME" -ForegroundColor Cyan
Write-Host "Version: $VERSION" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Clean up old build artifacts
Write-Host "Cleaning up old builds..." -ForegroundColor Yellow
if (Test-Path $TEMP_DIR) {
    Remove-Item -Recurse -Force $TEMP_DIR
}
Get-ChildItem -Path . -Filter "$MODULE_NAME-v*.zip" | Remove-Item -Force

# Create temporary build directory
Write-Host "Creating build directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

# Copy required files to build directory
Write-Host "Copying module files..." -ForegroundColor Yellow
Copy-Item "module.prop" $TEMP_DIR
Copy-Item "service.sh" $TEMP_DIR
Copy-Item "customize.sh" $TEMP_DIR
Copy-Item "uninstall.sh" $TEMP_DIR
Copy-Item "README.md" $TEMP_DIR

# Create ZIP file
Write-Host "Creating ZIP archive..." -ForegroundColor Yellow
Compress-Archive -Path "$TEMP_DIR\*" -DestinationPath $OUTPUT_ZIP -Force

# Clean up temporary directory
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Recurse -Force $TEMP_DIR

# Display results
if (Test-Path $OUTPUT_ZIP) {
    $FILE_SIZE = "{0:N2} KB" -f ((Get-Item $OUTPUT_ZIP).Length / 1KB)
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "✓ Build successful!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "Output: $OUTPUT_ZIP" -ForegroundColor White
    Write-Host "Size: $FILE_SIZE" -ForegroundColor White
    Write-Host ""
    Write-Host "To install:" -ForegroundColor Cyan
    Write-Host "1. Copy to your Android device" -ForegroundColor White
    Write-Host "2. Open Magisk Manager" -ForegroundColor White
    Write-Host "3. Install from storage" -ForegroundColor White
    Write-Host "4. Select $OUTPUT_ZIP" -ForegroundColor White
    Write-Host "5. Reboot" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit 1
}

