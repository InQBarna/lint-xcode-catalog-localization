#! /bin/sh

cd lint-xcode-catalog-localization-swiftui
xcodebuild -exportLocalizations -localizationPath ../../Sources/LintLocalizationTests/mocks/swiftui
cd ..

cd lint-xcode-catalog-localization-swiftui-untranslated
xcodebuild -exportLocalizations -localizationPath ../../Sources/LintLocalizationTests/mocks/swiftui-untranslated
cd ..

cd lint-xcode-catalog-localization-swiftui-twolangs
xcodebuild -exportLocalizations -localizationPath ../../Sources/LintLocalizationTests/mocks/swiftui-twolangs -exportLanguage es -exportLanguage en
cd ..
