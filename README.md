# lint-xcode-catalog-localization
Lint Xcode localization content using string catalogs

## Usage
To use this package, integrate it into your project via Swift Package Manager (SPM) and run the script LintLocalization with the following command:

```swift run LintLocalization /path/to/the/exported/folder/```

Replace /path/to/the/exported/folder/ with the actual path to the folder containing the .xcloc directories. The script will automatically find the .xliff files inside those directories and validate them.
