# Build environments

Taqseem mobile uses compile-time `--dart-define-from-file` config. Dev builds may be uploaded to internal TestFlight for testing, but must never be submitted as the production App Store release.

## Config files

| File | `APP_ENV` | `API_BASE_URL` |
|------|-----------|----------------|
| `config/dev.json` | `dev` | `https://api.dev.taqseem.uz/api` |
| `config/prod.json` | `prod` | `https://api.taqseem.uz/api` |

`APP_ENV` and `API_BASE_URL` must agree. Conflicting values throw at startup (`AppEnvironment.ensureValidConfiguration()`).

## Defaults (no define file)

- **Debug / profile** → dev API, DEV banner shown
- **Release / Xcode Archive** → **prod API**, no DEV banner

So a plain release build is safe to ship:

```bash
flutter build ios --release          # → api.taqseem.uz
flutter build apk --release          # → api.taqseem.uz
# Xcode → Product → Archive          # → api.taqseem.uz
```

To test against dev you must ask for it explicitly — with `config/dev.json` or
`scripts/build-dev-*.sh`. Dev builds may go to internal TestFlight, but must
never be submitted as the production App Store release.

> **Never set `AppConstants.defaultToDev = true`.** It makes a define-less
> Archive point at the dev server, which is easy to submit to the App Store by
> accident. The test `defaultToDev doim false` in
> `test/l10n_and_env_test.dart` guards this — do not delete it.

## Scripts

From the `mobile/` directory:

```bash
# Development API (safe for internal testing only)
./scripts/build-dev-apk.sh
./scripts/build-dev-ios.sh

# Production API (store / production releases)
./scripts/build-prod-apk.sh
./scripts/build-prod-ios.sh
```

Pass extra Flutter flags after the script, e.g. `./scripts/build-prod-apk.sh --split-per-abi`.

## Run locally

```bash
flutter run --dart-define-from-file=config/dev.json
flutter run --release --dart-define-from-file=config/prod.json
```

## English strings

Regenerate `lib/core/l10n/translations_en.dart` after editing `tool/en_overrides.json` or locale sources:

```bash
python3 tool/build_en_dart.py
```
