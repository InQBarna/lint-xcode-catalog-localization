//
//  LintLocalizationTests.swift
//  lint-xcode-catalog-localization
//
//  Created by Sergi Hernanz on 31/1/25.
//


import XCTest
@testable import LintLocalization

extension Array where Element == TranslationError {
    var sortedByLangKey: [TranslationError] {
        sorted(by: { e1, e2 in
            if e1.language == e2.language {
                return e1.key < e2.key
            } else {
                return e1.language < e2.language
            }
        })
    }
}

final class LintLocalizationTests: XCTestCase {

    func getFolderPath(mockName: String) throws -> String {
        guard let resourceURL = Bundle.module.resourceURL else {
            XCTFail("Failed to find the test bundle resource directory")
            fatalError()
        }
        var isDirectory: ObjCBool = false
        let folderPath = resourceURL
            .appendingPathComponent("mocks")
            .appendingPathComponent(mockName)
            .path
        let exists = FileManager.default.fileExists(
            atPath: folderPath,
            isDirectory: &isDirectory
        )
        XCTAssertTrue(exists && isDirectory.boolValue, "The directory does not exist")
        return folderPath
    }
    
    func testFindMockDirectory() throws {
        let folderPath = try getFolderPath(mockName: "fmp-full-export")
        let xliffPaths = try getXliffFileNames(from: folderPath)
        let errors = XliffValidator().validateXliffFiles(at: xliffPaths)
        XCTAssertEqual(
            errors.first,
            TranslationError(
                language: "ca",
                key: "",
                type: .empty
            )
        )
    }
    
    func testUntranslated() throws {
        let folderPath = try getFolderPath(mockName: "swiftui-untranslated")
        let xliffPaths = try getXliffFileNames(from: folderPath)
        let errors = XliffValidator().validateXliffFiles(at: xliffPaths)
        XCTAssertEqual(
            errors,
            [
                TranslationError(
                    language: "en",
                    key: "CFBundleName",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "NSHumanReadableCopyright",
                    type: .empty
                ),
                TranslationError(
                    language: "en",
                    key: "Empty translation",
                    type: .equalToKey
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .equalToKey
                )
            ]
        )
    }
    
    func testSwiftui() throws {
        let folderPath = try getFolderPath(mockName: "swiftui")
        let xliffPaths = try getXliffFileNames(from: folderPath)
        let errors = XliffValidator().validateXliffFiles(at: xliffPaths)
        XCTAssertEqual(
            errors,
            [
                TranslationError(
                    language: "en",
                    key: "CFBundleName",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "NSHumanReadableCopyright",
                    type: .empty
                ),
                TranslationError(
                    language: "en",
                    key: "Empty translation",
                    type: .equalToKey
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .equalToKey
                )
            ]
        )
    }
    
    func testSwiftuiTwoLangs() throws {
        let folderPath = try getFolderPath(mockName: "swiftui-twolangs")
        let xliffPaths = try getXliffFileNames(from: folderPath)
        let errors = XliffValidator().validateXliffFiles(at: xliffPaths)
        XCTAssertEqual(
            errors.sortedByLangKey,
            [
                TranslationError(
                    language: "en",
                    key: "CFBundleName",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Empty translation",
                    type: .equalToKey
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .equalToKey
                ),
                TranslationError(
                    language: "en",
                    key: "NSHumanReadableCopyright",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "CFBundleName",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "Empty translation",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "Hello, world!",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "Missing translation",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "NSHumanReadableCopyright",
                    type: .empty
                )
            ]
        )
    }
}
