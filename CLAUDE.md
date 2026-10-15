# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

JoyleeBook Mobile: a Flutter client for an online book/story reading platform. **The app is for the Reader role only.** Author and Admin features (creating, editing, or deleting series and chapters, moderation) belong to a separate Blazor web portal and must not be built here. Series endpoints are read-only (`GET`) from mobile. This is a PRN232 course project, and `docs/Flutter-Mobile-Code-Rules.md` is the grading rubric (15% Flutter core/storage, 15% UI/UX, 50% business logic/validation).

All user-facing text, code comments, and docs are in **Vietnamese**. Keep new strings and comments in Vietnamese to match.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only needed once @JsonSerializable / @riverpod code exists
flutter analyze
flutter test
flutter test test/ui/series_list_screen_test.dart                 # single file
flutter test --plain-name 'Hiển thị JoyleeEmptyState'             # single test by name

# Run against the shared hosted gateway (works on every emulator/simulator/device)
flutter run -t lib/main_development.dart
```

There is **no local backend** in this project; everyone uses the shared HTTPS gateway `https://api.joyleebook.duckdns.org` (`Environment.hostedBaseUrl` in `lib/config/environment.dart`). `--dart-define=API_BASE_URL=...` overrides it only to point at a different deployed gateway; it is the gateway root, never with `/api/...` appended. Cleartext HTTP is disabled in the Android manifests. Swagger: `https://api.joyleebook.duckdns.org/docs/authentication/swagger/index.html` and `https://api.joyleebook.duckdns.org/docs/series/swagger/index.html`. `lib/main_staging.dart` is currently empty.

## Backend integration

Every request goes through the shared **JoyleeBook API Gateway** at `https://api.joyleebook.duckdns.org` (YARP reverse proxy). Never call microservices directly or hard-code their ports. Endpoint paths live in `lib/config/api_endpoints.dart`, and the request/response contracts are in `docs/03-System-Flows-And-Contracts.md`. The in-app "Kiểm tra Gateway" tab (`lib/ui/gateway_test/`) probes gateway and downstream health. When it gets a 502, the gateway is running but the target microservice on the server is not.

## Architecture: "Compass App Hybrid"

The data and domain layers are organized by layer. The UI is organized by feature. Data flows one way: Widget → ViewModel → Repository → Service → Gateway.

- `lib/data/`
  - `services/api_client.dart`: Riverpod providers for the whole network stack. `gatewayBaseUrlProvider` holds a mutable base URL that the gateway test screen can change at runtime. `apiClientProvider` watches it, so changing the URL rebuilds Dio and every repository that depends on it. An interceptor attaches `Authorization: Bearer <token>` from `TokenStorage` (`flutter_secure_storage`). Note that `token_storage.dart` also contains a stale duplicate `createApiClient`. The one in `api_client.dart` is the one that's actually used.
  - `services/api_exceptions.dart`: `AppException.fromDio` maps `DioException` and HTTP status codes to friendly Vietnamese messages. Raw errors must never reach the UI.
  - `dtos/`: these mirror the gateway JSON and absorb nulls and field-name variants (e.g. `coverImageUrl`/`coverUrl`). They're currently hand-written `fromJson`. The docs call for `@JsonSerializable`.
  - `repositories/`: the only bridge between services and ViewModels. Each method catches `DioException`, rethrows it as `AppException`, and maps DTO → domain model before returning. Each repository has its own `Provider` (e.g. `seriesRepositoryProvider`). Tests override that provider.
- `lib/domain/models/`: pure, immutable Dart models. They must not import material, dio, sqflite, or riverpod (`Series.fromDto` importing the DTO is the existing exception). Use `copyWith` for state changes.
- `lib/ui/<feature>/{view_models,widgets}/`: ViewModels are hand-written `AsyncNotifier`/`Notifier` subclasses with manually declared `NotifierProvider`s. `riverpod_generator` is a dependency but isn't used yet. Widgets are `ConsumerWidget`s that only `ref.watch` state and call ViewModel methods through `ref.read`.
- `lib/ui/core/`: Warm Editorial theme (`themes/app_colors.dart`, `app_dimensions.dart`, `app_theme.dart`; Material 3, light and dark) and shared `Joylee*` widgets. A widget belongs in `core/widgets/` only if two or more features use it, it's a brand primitive, or it's a system-state view. Core widgets accept only primitive and callback parameters, never domain models. See `docs/Flutter-Mobile-Design-System.md` (Flutter implementation) and `docs/Design-System.md` (cross-platform token/component spec shared with the web); Figma library structure and build progress are in `docs/Design-Figma.md`.
- Routing: the docs specify `lib/routing/app_router.dart` with `go_router` and an auth redirect guard to `/sign-in`, but it doesn't exist yet. `lib/app.dart` currently switches between screens with a `NavigationBar` + `IndexedStack`.

`lib/ui/series/` together with `docs/04-Feature-Implementation-Guide.md` is the reference template for new features: DTO → domain model → repository + provider → ViewModel → 4-state screen → fake + widget test.

## Required behaviors (from the docs and graded)

- **4 states on every data screen**: loading, empty (with a suggested action), error (with a Retry button, via `JoyleeErrorView`), and data (with `RefreshIndicator`). No RenderFlex overflow; wrap forms in `SingleChildScrollView` + `SafeArea`.
- **Search debounce of 400 ms** in the ViewModel (see `SeriesListViewModel.search`).
- **Optimistic UI with rollback** for bookmark and like: update state first, call the API, restore the original item on failure, and show a SnackBar.
- **Double-submit prevention**: set `isLoading` and `onPressed: null` while a request is in flight.
- **401 handling** (not implemented yet): clear the token, set the session to unauthenticated, redirect to `/sign-in`, and show only one "session expired" message even when several requests fail at once.
- Validation rules for auth forms (username 3–64 chars `[A-Za-z0-9._-]`; password 8–128 chars with at least one letter and one digit) are in the code-rules doc.
- Storage tiers: JWT goes in `flutter_secure_storage` only. Preferences go in `shared_preferences`. Offline reading history goes in `sqflite` (FIFO, 50 chapters). The last two aren't in `pubspec.yaml` yet.

## Testing

Fakes live in `testing/fakes/` (outside `test/`) and are imported by relative path (`../testing/fakes/...` or `../../testing/fakes/...`). They `implement` the real repository class. In widget tests, wrap the widget in a `ProviderScope` with `overrides: [xRepositoryProvider.overrideWithValue(FakeX(...))]`, then call `pumpAndSettle()`. Tests never hit the network.
