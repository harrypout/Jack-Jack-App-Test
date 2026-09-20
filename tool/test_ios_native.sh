#!/usr/bin/env bash
# Run the actual iOS plugin contract test after compiling the simulator app.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p coverage
jackjack_simulator_id="${JACKJACK_SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime, entries in sorted(devices.items(), reverse=True):
    if ".iOS-" not in runtime:
        continue
    for device in entries:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("No available iPhone simulator; install an iOS runtime in Xcode.")
')}"
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$jackjack_simulator_id" \
  -destination-timeout 180 \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | tee coverage/ios-native-tests.log
