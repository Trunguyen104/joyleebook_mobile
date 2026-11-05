# AGENTS.md

Guidance for coding agents working in this repository. Based on `CLAUDE.md`, with implementation details checked against the current codebase.

## Project scope and language

- JoyleeBook Mobile is a Flutter client for an online book/story reading platform, exclusively for the **Reader** role.
- Author and Admin workflows belong to the separate Blazor web portal. Do not add series/chapter creation, editing, deletion, or moderation here. Mobile series endpoints are read-only (`GET`). Reader actions such as bookmarks, ratings, and reading progress use their own API contracts.
- Keep user-facing strings, new code comments, and project documentation in **Vietnamese**, following existing conventions. This `AGENTS.md` is in English by explicit request.
- This is a PRN232 course project. `docs/Flutter-Mobile-Code-Rules.md` defines the grading rubric: 15% Flutter core/storage, 15% UI/UX, and 50% business logic/validation.

## Read before changing code

Use the documents relevant to the task:

- `docs/01-System-Scope-Reader.md`: Reader scope and business rules.
- `docs/02-Mobile-Architecture.md`: architecture, storage, and error handling.
- `docs/03-System-Flows-And-Contracts.md`: business flows and gateway contracts.
- `docs/04-Feature-Implementation-Guide.md`: reference feature implementation.
- `docs/Flutter-Mobile-Code-Rules.md`: required behaviors and validation.
- `docs/Flutter-Mobile-Design-System.md`: Flutter themes and shared widgets.
- `docs/Design-System.md`: cross-platform design tokens and components.
- `docs/Design-Figma.md`: Figma library structure and progress.
- `docs/Flutter-Mobile-Setup.md`: setup and gateway integration.

Check actual source files and `pubspec.yaml` before assuming a documented feature or dependency is already implemented. Keep planned requirements distinct from existing behavior.

## Documentation lookup with Context7

Use Context7 MCP for current documentation whenever a task involves a library, framework, SDK, API, CLI tool, or cloud service, including syntax, configuration, migrations, setup, and library-specific debugging. This applies even to familiar tools such as Flutter, Riverpod, Dio, and go_router.

1. Start with `resolve-library-id`, supplying the library name and the documentation question, unless an exact `/org/project` library ID was provided.
2. Select the best match by exact name, description relevance, snippet count, source reputation (prefer High/Medium), and benchmark score. Retry with another name or query if the results are unsuitable. Use a version-specific ID when a version is specified.
3. Call `query-docs` with the selected ID and a focused question about one concept. Query distinct concepts separately, unless the question concerns their interaction.
4. Base library-specific implementation guidance on the retrieved documentation. Prefer Context7 over web search for library documentation.

Context7 is not required for pure refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts when no library documentation is needed.

## Development commands

Run commands from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/ui/series_list_screen_test.dart
flutter test --plain-name 'Hiển thị JoyleeEmptyState'
flutter run -t lib/main_development.dart
```

Generate code only when the affected code uses generation annotations such as `@JsonSerializable` or `@riverpod`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The current DTOs and providers are hand-written; generator dependencies alone do not mean generation is required. `lib/main_staging.dart` is currently empty.

After code changes, format affected Dart files with `dart format`, run `flutter analyze`, and run the relevant tests. Run the full test suite for changes that affect shared behavior. Report any checks that could not run and why. Documentation-only changes do not require Flutter tests.

## Gateway and API integration

- There is no local backend in this repository. Use the shared HTTPS gateway at `https://api.joyleebook.duckdns.org`, defined by `Environment.hostedBaseUrl` in `lib/config/environment.dart`.
- All requests go through this YARP gateway. Never call microservices directly or hard-code their ports.
- `--dart-define=API_BASE_URL=...` may point to another deployed gateway. Supply the gateway root, without an `/api/...` suffix.
- Keep endpoint paths in `lib/config/api_endpoints.dart` and follow `docs/03-System-Flows-And-Contracts.md` for payloads and responses.
- Android manifests disable cleartext HTTP; preserve HTTPS configuration.
- The gateway test feature in `lib/ui/gateway_test/` can change the base URL at runtime and probe downstream health. A 502 indicates that the gateway responded but its downstream service is unavailable.
- Swagger references: `https://api.joyleebook.duckdns.org/docs/authentication/swagger/index.html` and `https://api.joyleebook.duckdns.org/docs/series/swagger/index.html`.

## Architecture: Compass App Hybrid

Data and domain are organized by layer; UI is organized by feature. Preserve the one-way flow:

```text
Widget → ViewModel → Repository → Service → Gateway
```

- `lib/data/services/`: networking, token storage, and other service integrations. `api_client.dart` owns network providers. `apiClientProvider` watches `gatewayBaseUrlProvider`, so a base URL change rebuilds Dio and dependent repositories.
- `lib/data/dtos/`: gateway JSON representations. Handle nulls and supported field-name variants here. Follow existing hand-written `fromJson` conventions unless generation is explicitly part of the task.
- `lib/data/repositories/`: the bridge between services and ViewModels. Catch `DioException`, convert it into `AppException`, and map DTOs to domain models before returning. Give repositories providers that tests can override.
- `lib/domain/models/`: immutable Dart models. Avoid dependencies on Flutter Material, Dio, sqflite, or Riverpod. The existing `Series.fromDto` DTO import is an exception, not a reason to introduce more cross-layer dependencies. Use `copyWith` for state changes.
- `lib/ui/<feature>/view_models/`: hand-written `AsyncNotifier`/`Notifier` classes with manually declared providers. Put business logic and request orchestration here.
- `lib/ui/<feature>/widgets/`: widgets watch state with `ref.watch` and call ViewModel methods through `ref.read`. Do not call Dio or services directly from widgets.
- `lib/ui/core/`: shared Warm Editorial theme and `Joylee*` widgets. Reuse `AppColors`, `AppDimensions`, and `AppTheme`, supporting Material 3 light/dark themes.
- Promote a widget to `core/widgets/` only when at least two features use it, it is a brand primitive, or it represents a system state. Core widget parameters should be primitives and callbacks, not domain models.

Use `lib/ui/series/` and the feature implementation guide as the template: DTO → domain model → repository/provider → ViewModel → four-state screen → fake and tests.

## Routing and authentication

- Define navigation in `lib/routing/app_router.dart` and paths in `lib/routing/app_paths.dart` (`AppPaths`). Do not scatter hard-coded route strings across widgets.
- The current `StatefulShellRoute.indexedStack` has four tabs: `/series`, `/bookmarks`, `/profile`, and `/gateway`.
- Series browsing is public. Profile and bookmark routes, including bookmark subroutes, require authentication. Keep authentication redirects centralized in the router's `redirect` function.
- `/sign-in`, `/sign-up`, and `/forgot-password` are outside the tab shell. Preserve the `from` query parameter for return navigation.
- Series detail and chapter list open inside the series tab with `context.push`. The chapter reader uses the root navigator for full-screen reading; previous/next chapter navigation uses `context.pushReplacement`.
- Route `extra` is only an optional display hint. Screens must work when it is absent.
- Use go_router for screens rather than `Navigator.push` with `MaterialPageRoute`. Dialogs may close with `Navigator.pop`.
- `authSessionProvider` in `lib/ui/auth/view_models/auth_session_view_model.dart` restores the session from secure storage and drives routing and profile state. A null session means signed out.
- `AuthInterceptor` attaches the bearer token, refreshes once for concurrent 401 responses, and retries waiting requests. Requests such as sign-in, sign-up, and sign-out use `Options(extra: {AuthInterceptor.skipAuthRefresh: true})` when a 401 should not trigger refresh.
- When refresh is rejected, clear tokens and mark `sessionExpiredProvider`. Preserve the single session-expired notification and redirect handled by `lib/app.dart`, even if multiple requests fail together.
- Sign-out requires a confirmation `AlertDialog` with a danger-colored confirm button. Always clear local tokens even if the remote sign-out fails.

## Required UI and business behavior

- Every data screen supports loading, empty with a suggested action, error with Retry using `JoyleeErrorView`, and data with refresh support using `RefreshIndicator` where applicable.
- Avoid RenderFlex overflow. Forms must handle small screens and the keyboard using `SingleChildScrollView` and `SafeArea`.
- Debounce search by 400 ms in the ViewModel, following `SeriesListViewModel.search`.
- Bookmark and like actions require optimistic updates: update immediately, call the API, restore the original state on failure, and show a SnackBar.
- Prevent double submission by exposing loading state and setting `onPressed: null` while a request is pending.
- Convert network errors to friendly Vietnamese messages through `AppException.fromDio`; never expose raw exceptions to users.
- Reuse `lib/ui/auth/view_models/auth_validators.dart`. Sign-up usernames are 3–64 characters matching `[A-Za-z0-9._-]`; passwords are 8–128 characters with at least one letter and one digit. Sign-in only requires non-empty fields because the backend also accepts email.

## Storage

- Store access and refresh JWTs only through `TokenStorage` using `flutter_secure_storage`.
- Store preferences in `shared_preferences`, which is already a dependency. Reading preferences are handled in `lib/data/services/reading_preferences_service.dart`.
- The documented offline chapter-history requirement is sqflite with a FIFO limit of 50 chapters. sqflite is not currently a dependency; do not describe offline persistence as implemented. The existing library reading history/progress uses API integration.

## Testing conventions

- Keep reusable fakes in `testing/fakes/`, outside `test/`, and import them by relative path.
- Fakes implement real repository classes. Override repository providers inside `ProviderScope`, for example with `seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository(...))`, using the fake's actual constructor.
- Follow existing widget tests for setup and use `pumpAndSettle()` when appropriate for the tested widget state.
- Tests building `JoyleeBookApp` or `ProfileScreen` must override `authRepositoryProvider` to avoid reaching the secure-storage plugin and hanging. Use `FakeTokenStorage` when token storage is involved.
- Tests must not hit the real network. Use fake repositories or controlled Dio adapters/interceptors.
- Cover affected business rules, state transitions, error handling, and rollback behavior with meaningful tests. Keep unrelated code changes out of the task.
