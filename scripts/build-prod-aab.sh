#!/usr/bin/env bash
# Play Store uchun: prod API'ga ulangan App Bundle.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build appbundle --dart-define-from-file=config/prod.json "$@"
