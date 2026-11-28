# Pozzo · Flutter

Cross-platform application of Pozzo, the savings group (junta) app by Kerolabs, for Android, iOS and the web.
It consumes the Pozzo RESTful services, documented at <https://api-kerolabs.duckdns.org/swagger-ui/index.html>.

## Structure

The code follows the layout of the course: `lib/core` for what every feature shares, and one folder per bounded
context under `lib/features`, each one split in four layers.

```
lib/
  core/                      service locator (get_it), database (sqflite), HTTP client, theme, formats
                             and the widgets every screen shares
  features/
    main/                    bottom bar with Juntas, Historial, Avisos and Perfil, and the links of the notices
    iam/                     access with the phone, profile
    savings_groups/          groups, members, invitations and turns
    contributions/           periods, contributions, receipts, pot and auctions
    compliance_history/      compliance history and shared history
    notifications/           notices and reminders
      application/           use cases
      domain/                entities and repository contracts
      infrastructure/        API clients, DTOs, mappers, DAOs and repository implementations
      presentation/          pages, widgets, view models and their state
```

Packages: `http` for the services, `get_it` for dependency injection, `sqflite` for local storage (session,
groups and the last copy of the contributions, to show them without signal), `image_picker` for the photos of
receipts and profiles and `url_launcher` for the Terms and the Privacy Policy.

Each page creates its view model from the service locator and listens to it with a `ListenableBuilder`; the view
model keeps an immutable state and calls the use cases, which only know the repository contracts of the domain.

What the Android application does with native services is left out: the push notifications (Firebase Cloud
Messaging; the notices are read from the inbox in the "Avisos" tab) and the reading of receipts on the phone (ML Kit;
the member writes the data of the receipt and its photo is kept with the contribution).

## Getting started

The project uses Flutter 3.47.7 (Dart 3.13.5), the same version the CI runs.

```
flutter pub get
git config core.hooksPath .githooks
flutter run
```

The hook checks that every commit follows Conventional Commits, as the `Commit policy` workflow does on GitHub.
Work on a branch from `develop` and open a pull request to `develop`; `main` only receives releases.

## Checks

```
flutter analyze
flutter test
```

Both run on every push in the `Flutter` workflow.
