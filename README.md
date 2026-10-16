# Zedu Desktop

A lean Flutter app using Clean Architecture, Material 3, and Riverpod. The codebase is organized for desktop and mobile targets, with an **auth** feature (login, session, and API wiring) as the reference vertical slice.

## Stack

- Flutter 3.x / Dart `^3.11`
- Material 3, Roboto and Lato fonts (see `pubspec.yaml`)
- Riverpod, GetIt, GoRouter
- Dio, `flutter_dotenv`
- `flutter_secure_storage`, `flutter_svg`
- Mocktail (tests), `flutter_lints` plus strict analyzer language flags in `analysis_options.yaml`

## Project layout

```txt
.
├── .env.example          # Tracked template; bundled as a Flutter asset
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── app.dart
│   ├── core/
│   │   ├── core.dart
│   │   ├── api_utils/        # ApiBaseService, failures, auth interceptor
│   │   ├── config/           # AppConfig, env loader, flavor
│   │   ├── locator/
│   │   ├── navigator/        # GoRouter (e.g. login route)
│   │   ├── secure_storage/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   └── features/
│       ├── features.dart
│       └── auth/
│           ├── auth.dart
│           ├── data/
│           ├── domain/
│           └── presentation/
├── test/
│   ├── helpers/
│   ├── unit/features/auth/data/
│   └── widget/features/auth/presentation/views/
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

## Architecture

Each feature owns its UI, business rules, repository contract, and data implementation.

```txt
presentation -> domain <- data
```

- `app`: bootstrap and root `MaterialApp.router`.
- `core`: shared infrastructure (DI, HTTP, env, routing, theme, secure storage).
- `features`: vertical modules; today this is **`auth`** (login flow and session models).

Example flow:

```txt
LoginView
  -> auth providers (Riverpod)
  -> AuthRepository
  -> AuthRemoteDataSource
  -> ApiBaseService
```

## Core rules

Keep `core` small. Add shared code only when more than one feature needs it.

Good `core` candidates: app config, dependency injection, API client and failures, navigation, secure storage, logging, theme, and cross-cutting utilities.

## Barrel exports

Every folder that exposes reusable Dart files should have a barrel file.

Use **exactly these two root-barrel imports** when you need shared core plus feature exports (same order and URIs as `lib/features/auth/data/datasource/auth_remote_datasource.dart`):

```dart
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
```

If you rename the app in `pubspec.yaml`, update the `package:` name in both lines to match.

Export chain:

```txt
leaf files -> layer barrel -> feature barrel -> features.dart
shared core files -> core.dart
```

Rules:

- Add new exports whenever you add a reusable file.
- Prefer `core/core.dart` for shared app infrastructure.
- Prefer `features/features.dart` when code needs feature-level exports.
- Inside a feature, use the narrowest useful barrel when `features.dart` would create an import cycle—often a **layer** barrel (`data/data.dart`, `domain/domain.dart`, `presentation/presentation.dart`) or a **subfolder** barrel.

**Narrower than `features.dart`:** import that feature’s barrel first, e.g. `lib/features/auth/auth.dart`. Reach for layer or subfolder barrels only when you need a smaller slice to break a cycle or keep dependencies obvious.

## Configuration

Env keys are read from **dotenv** after `loadAppEnv()` in `main.dart`. The repo bundles **`.env.example`** and a local **`.env`** as Flutter assets. `.env` is gitignored, so create it from the template before you run or build.

`loadAppEnv()` tries `.env` first, then `.env.example`. Both `.env` and `.env.example` are listed under `flutter.assets` in `pubspec.yaml`, so a build fails with `No file or variants found for asset: .env` when `.env` is missing. Create `.env` from `.env.example` before `flutter run` or `flutter build`.

1. Copy `.env.example` to `.env`, then edit values in `.env` for local overrides (avoid committing secrets).
2. Prefer CI variables or `--dart-define` for production secrets.

```txt
API_BASE_URL=https://api.staging.zedu.chat/api/v1/
USE_MOCK_DATA=false
APP_FLAVOR=development
```

`USE_MOCK_DATA` accepts `true` / `false` (also `1` / `0`, `yes` / `no`). `APP_FLAVOR` accepts `development`, `staging`, or `production` (case-insensitive).

### Overrides for CI or release builds

`--dart-define` overrides dotenv when you need non-file config:

```sh
flutter run --dart-define=API_BASE_URL=https://api.example.com --dart-define=USE_MOCK_DATA=false --dart-define=APP_FLAVOR=production
```

Defaults when neither `.env` / `.env.example` nor defines set a value (see `AppConfig.fromEnvironment` and `AppFlavorConfig`):

```txt
API_BASE_URL=https://api.staging.zedu.chat/api/v1/
USE_MOCK_DATA=false
APP_FLAVOR=development
```

## Clone

The repository root **is** the Flutter project (`pubspec.yaml` and `lib/` at the top level).

```sh
git clone https://github.com/hngprojects/zedu-desktop.git
cd zedu-desktop
```

## Quick start

Create `.env` from the template first. The build needs this file.

```sh
cp .env.example .env
```

Windows (PowerShell):

```powershell
Copy-Item .env.example .env
```

Then get the packages and run the app:

```sh
flutter pub get
flutter run
```

## Running on Windows(locally)

Windows needs a few extra steps on a fresh clone to run locally, including a manual fix for the Agora plugin in your Pub cache. The full guide is in [`windows-setup-locally.md`](windows-setup-locally.md).

Tested with Flutter 3.47.7 and Visual Studio 2026 Community (Desktop development with C++). Run every command in PowerShell, do not run Flutter as administrator, and never commit or share your `.env` file.

The guide walks from a fresh clone to a running app and covers these build errors:

- `Cannot extract through symlink` from the Agora plugin
- `No file or variants found for asset: .env`
- `error STL1011` in `audioplayers_windows`
- `file cannot create directory: C:/Program Files/zedu` during install


## Common commands

```sh
dart format lib test
flutter analyze
flutter test
```

Use `flutter analyze` for this project so the Flutter SDK and bundled assets resolve correctly.

## Testing

Tests mirror the app layout:

- `test/helpers`: reusable test setup (e.g. `TestMaterialApp`)
- `test/unit`: datasources, repositories, and services
- `test/widget`: views and important UI flows

Mock dependencies at the layer boundary being tested.
