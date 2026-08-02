# Build environments

Taqseem mobile uses compile-time `--dart-define-from-file` config. **Never submit dev builds to app stores.**

## Config files

| File | `APP_ENV` | `API_BASE_URL` |
|------|-----------|----------------|
| `config/dev.json` | `dev` | `https://api.dev.taqseem.uz/api` |
| `config/prod.json` | `prod` | `https://api.taqseem.uz/api` |

`APP_ENV` and `API_BASE_URL` must agree. Conflicting values throw at startup (`AppEnvironment.ensureValidConfiguration()`).

## Defaults (no define file)

- **Debug / profile** → dev API, DEV banner shown
- **Release** → production API, no DEV banner

You can still point a **release** build at dev explicitly:

```bash
flutter build apk --release --dart-define-from-file=config/dev.json
```

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
