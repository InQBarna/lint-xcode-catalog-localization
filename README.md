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

### Optional Flag: `--no-keys`

By default, the script checks for **string keys** in the localization files. If you prefer to use **base localization identifiers** instead of keys, you can disable the key-checking behavior with the `--no-keys` flag. This will prevent errors for keys that are equal to their respective values.

```
mint run InQBarna/lint-xcode-catalog-localization PROJECT.xcodeproj --no-keys
```
When `--no-keys` is not specified, **string keys** will be used by default.

## Installation and Usage cloning the repo

```
git clone https://github.com/InQBarna/lint-xcode-catalog-localization.git
cd lint-xcode-catalog-localization
swift run LintLocalization PROJECT.xcodeproj
cd ..
```
