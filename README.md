# lint-xcode-catalog-localization

Lint Xcode localization content using string catalogs

Run against your xcodeproj/xcworkspace to detect missing localizations

*Features*

- Failure if any key has a missing translation (empty).
- Failure if any translation is equal to key (for key-based localization).
- List all missing translations (including translation equal to key).

*TODO*

- Warning-style output format so script can be used as build script step.


*Please note it only works for projects using string catalogs*

## Installation (mint)

```mint install InQBarna/lint-xcode-catalog-localization```

## Usage (mint)

```
mint run InQBarna/lint-xcode-catalog-localization PROJECT.xcodeproj
```

It also works for xcworkspaces

```
mint run InQBarna/lint-xcode-catalog-localization WORKSPACE.xcworkspace
```

### Flag

By default, the script checks for matching keys and values, considering this an error when they are identical. To disable this, there's the `--no-keys` flag, allowing keys to be equal to their values

```
mint run InQBarna/lint-xcode-catalog-localization PROJECT.xcodeproj --no-keys
```

## Installation and Usage cloning the repo

```
git clone https://github.com/InQBarna/lint-xcode-catalog-localization.git
cd lint-xcode-catalog-localization
swift run LintLocalization PROJECT.xcodeproj
cd ..
```
