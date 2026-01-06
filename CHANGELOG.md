# Changelog

All notable changes to the Force Ethernet Always On module will be documented in this file.

## [2.3] - 2025-01-06

### Added
- **Auto Screen Wake**: Automatically wakes up screen if it's off during UI automation
  - Checks screen power state using `dumpsys power`
  - Sends `KEYCODE_WAKEUP` to turn on screen
  - Attempts simple unlock with swipe gesture
  - Ensures UI automation can interact with settings even when screen is off
  - Logs screen state and wake-up attempts

### Changed
- Updated documentation to reflect new screen wake feature
- Renumbered automation steps in README and AUTOMATION_FLOW to include screen wake as Step 1

## [2.2] - 2025-01-06

### Added
- **Log Rotation**: Automatically deletes log file if it exceeds 10KB
  - Checks file size on service startup
  - Starts with fresh log when size limit exceeded
  - Prevents log files from growing indefinitely

### Changed
- **Faster Retry**: Reduced retry interval from 5 minutes to 1 minute
  - Faster recovery if automation fails initially
  - More responsive to network availability changes

### Improved
- **Better Reconnection Handling**: 
  - Resets automation flag when cable is disconnected
  - Allows immediate retry on cable reconnection
  - Handles scenarios where automation fails before IP is obtained

## [2.1] - Previous Version

### Features
- Pure UI automation for Ethernet enabling
- Carrier detection for cable connection monitoring
- 3-tier toggle detection (UIAutomator, Screen positioning, DPAD)
- Smart verification of IP assignment
- Auto-retry logic with cooldown
- Comprehensive logging
- Boot integration
- Works on locked-down Android systems

---

## Installation

Download the latest version ZIP file and flash it through Magisk Manager.

## Notes

- **Screen Lock**: Auto wake-up works with simple swipe locks. PIN/password/pattern locks require manual unlock.
- **Log File**: Located at `/data/local/tmp/force_eth.log`
- **Compatibility**: Android 14, 15, 16+ with Magisk 20.4+

