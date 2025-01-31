# lint-xcode-catalog-localization
Lint Xcode localization content using string catalogs

## Installation

### Using mint
```mint install InQBarna/lint-xcode-catalog-localization```

### Cloning
```git clone https://github.com/InQBarna/lint-xcode-catalog-localization.git```

## Usage (Version 0.1.0)

### Using mint

```
xcodebuild -exportLocalizations \
    -workspace WORKSPACE.xcworkspace \
    -localizationPath xcloc_exported_folder \
    -exportLanguage es \
    -exportLanguage en
mint run InQBarna/lint-xcode-catalog-localization xcloc_exported_folder
rm -Rf tmp_exported_folder
```

### Cloning

```
xcodebuild -exportLocalizations \
    -workspace WORKSPACE.xcworkspace \
    -localizationPath xcloc_exported_folder \
    -exportLanguage es \
    -exportLanguage en
    
cd lint-xcode-catalog-localization
swift run LintLocalization ../xcloc_exported_folder
cd ..

rm -Rf tmp_exported_folder
```

## Usage (TODO: Next versions)

```mint run InQBarna/lint-xcode-catalog-localization WORKSPACE.xcworkspace```
