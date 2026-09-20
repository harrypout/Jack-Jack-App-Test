#!/usr/bin/env bash
# Full is the release gate; baseline/known are diagnostic subsets only.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-full}"
case "$mode" in full|baseline|known) ;; *) echo 'Usage: tool/check.sh [full|baseline|known]' >&2; exit 2 ;; esac
mkdir -p coverage

flutter --version --machine > coverage/flutter-version.json
python3 - <<'PY'
import json
from pathlib import Path
expected = json.loads(Path('.fvmrc').read_text())['flutter']
actual = json.loads(Path('coverage/flutter-version.json').read_text())['frameworkVersion']
if expected != actual:
    raise SystemExit(f'Use Flutter {expected}; active SDK is {actual}. No SDK was changed.')
PY

if [[ ! -f .env ]]; then
  cp test/fixtures/ble.env .env
  echo 'Created a synthetic .env for local tests/unsigned builds; use real BLE configuration before device testing.'
fi
pub_args=(--enforce-lockfile)
if [[ "${JACKJACK_OFFLINE:-0}" == 1 ]]; then pub_args+=(--offline); fi
flutter pub get "${pub_args[@]}"
dart run build_runner build --delete-conflicting-outputs
meter_sources=(
  lib/providers
  lib/services
  lib/models/ble_service.dart
  lib/models/notification_sf.dart
  lib/widgets/monitoring_readiness.dart
  lib/utils/theme_manager.dart
  lib/widgets/ble_gauge.dart
  lib/utils/status_colors.dart
  lib/providers/last_recorded_alert_provider.dart
  lib/screens/home/widgets/selected_device_widget.dart
)
dart format --output=none --set-exit-if-changed test lib/providers/alert_clock_provider.dart "${meter_sources[@]}"

# Legacy warnings stay visible. Analyzer errors are blocking immediately.
analysis_status=0
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings 2>&1 | tee coverage/analyze.log || analysis_status=$?
# Keep the new suite and injection boundaries free of warnings and infos.
dart analyze --fatal-infos test lib/providers/alert_clock_provider.dart lib/models/ble_service.dart lib/providers/threshold_alert_provider.dart "${meter_sources[@]}" lib/screens/manual_monitoring/manual_monitoring_screen.dart 2>&1 | tee coverage/analyze-tests.log || analysis_status=$?
test_args=(--no-pub --coverage --reporter expanded)
if [[ "$mode" == baseline ]]; then test_args+=(--exclude-tags known_issue); fi
if [[ "$mode" == known ]]; then test_args+=(--tags known_issue); fi
test_status=0
flutter test "${test_args[@]}" 2>&1 | tee "coverage/tests-$mode.log" || test_status=$?
if (( analysis_status != 0 || test_status != 0 )); then exit 1; fi
