#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build apk --dart-define-from-file=config/dev.json "$@"
