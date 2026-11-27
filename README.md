# Pozzo · Flutter

Cross-platform application of Pozzo, the savings group (junta) app by Kerolabs. It consumes the same RESTful
services as the native Android application ([pozzo-mobile](https://github.com/kerolabs/pozzo-mobile)), deployed at
<https://api-kerolabs.duckdns.org/swagger-ui/index.html>.

## Structure

The code follows the layout of the course: `lib/core` for what every feature shares, and one folder per bounded
context under `lib/features`, each one split in four layers.

```
lib/
  core/                      service locator (get_it) and theme
  features/
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

Packages: `http` for the services, `get_it` for dependency injection and `sqflite` for local storage.

## Getting started

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
