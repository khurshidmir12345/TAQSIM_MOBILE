#!/usr/bin/env bash
# Ichki sinov uchun: dev API'ga ulangan App Bundle.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build appbundle --dart-define-from-file=config/dev.json "$@"
