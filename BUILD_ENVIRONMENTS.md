# Build environments

Taqseem mobile uses compile-time `--dart-define-from-file` config. Dev builds may be uploaded to internal TestFlight for testing, but must never be submitted as the production App Store release.

## Config files

| File | `APP_ENV` | `API_BASE_URL` |
|------|-----------|----------------|
| `config/dev.json` | `dev` | `https://api.dev.taqseem.uz/api` |
| `config/prod.json` | `prod` | `https://api.taqseem.uz/api` |

`APP_ENV` and `API_BASE_URL` must agree. Conflicting values throw at startup (`AppEnvironment.ensureValidConfiguration()`).

## Defaults (no define file)

> ⚠️ **TEMPORARY: `AppConstants.defaultToDev` is currently `true`.**
> Every build — including a define-less Archive — points at **dev**
> (`api.dev.taqseem.uz`). This is deliberate: the push-notification backend
> only exists on dev while it is being tested via TestFlight.
>
> **Set it back to `false` before the next App Store submission.**

Current behaviour while the flag is `true`:

| Build | API | DEV banner |
|-------|-----|-----------|
| Debug / profile | dev | shown |
| Release / Archive | **dev** | **shown** |
| `config/prod.json` (`build-prod-*.sh`) | prod | hidden |

Once the flag is set back to `false`:

| Build | API | DEV banner |
|-------|-----|-----------|
| Debug / profile | dev | shown |
| Release / Archive | **prod** | hidden |

**How to tell what you are about to ship:** open the app. If the **DEV banner**
is visible, the build talks to dev — do not submit it to the App Store. An
explicit `config/prod.json` build always overrides the flag, so
`./scripts/build-prod-ios.sh` is safe to ship at any time.

Dev builds may go to internal TestFlight, but must never be submitted as the
production App Store release.

> The test `definessiz release: bayroqqa mos va DEV holati ko‘rinadigan` in
> `test/l10n_and_env_test.dart` guards the safety property: whenever a
> define-less release build points at dev, it must also be flagged as dev so
> the banner appears. Do not delete it.

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
