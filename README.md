# lint-xcode-catalog-localization

Lint Xcode localization content using string catalogs

Run against your xcodeproj/xcworkspace to detect missing localizations

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

## Installation and Usage cloning the repo

```
git clone https://github.com/InQBarna/lint-xcode-catalog-localization.git
cd lint-xcode-catalog-localization
swift run LintLocalization PROJECT.xcodeproj
cd ..
```
