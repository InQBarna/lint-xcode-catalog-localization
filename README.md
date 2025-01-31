# lint-xcode-catalog-localization
Lint Xcode localization content using string catalogs

## Installation

### Using mint
```mint install InQBarna/lint-xcode-catalog-localization```

### Cloning
```git clone https://github.com/InQBarna/lint-xcode-catalog-localization.git```
```cd lint-xcode-catalog-localization```

## Usage (Version 0.1.0)

### Using mint
```mint run InQBarna/lint-xcode-catalog-localization xcloc_exported_folder```

### Cloning
```
cd lint-xcode-catalog-localization
swift run LintLocalization xcloc_exported_folder
```

## Integrate with xcode workflows

```
xcodebuild -exportLocalizations \
    -workspace WORKSPACE.xcworkspace \
    -localizationPath xcloc_exported_folder \
    -exportLanguage es \
    -exportLanguage en
# Mint usage
mint run InQBarna/lint-xcode-catalog-localization xcloc_exported_folder
rm -Rf tmp_exported_folder
```
