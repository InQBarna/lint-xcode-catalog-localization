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
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: true)
        try XCTAssertEqualDiff(
            errors.first,
            TranslationError(
                language: "ca",
                key: "",
                type: .empty
            )
        )
    }
    
    func testFindMockDirectoryNoKeys() throws {
        let folderPath = try getFolderPath(mockName: "fmp-full-export")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: false)
        try XCTAssertEqualDiff(
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
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: true)
        try XCTAssertEqualDiff(
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
                    key: "Hello, world!",
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
    
    func testUntranslatedNoKeys() throws {
        let folderPath = try getFolderPath(mockName: "swiftui-untranslated")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: false)
        try XCTAssertEqualDiff(
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
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Hello, world!",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .newMeansNoLocalized
                )
            ]
        )
    }
    
    func testSwiftui() throws {
        let folderPath = try getFolderPath(mockName: "swiftui")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: true)
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
    
    func testSwiftuiNoKeys() throws {
        let folderPath = try getFolderPath(mockName: "swiftui")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: false)
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
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .newMeansNoLocalized
                )
            ]
        )
    }
    
    func testSwiftuiTwoLangs() throws {
        let folderPath = try getFolderPath(mockName: "swiftui-twolangs")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: true)
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
                    key: "Hello, world!",
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
                    language: "en",
                    key: "Not compiled translation",
                    type: .equalToKey
                ),
                TranslationError(
                    language: "en",
                    key: "nsloc1",
                    type: .equalToKey
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
                ),
                TranslationError(
                    language: "es",
                    key: "Not compiled translation",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "nsloc1",
                    type: .empty
                )
            ]
        )
    }
    
    func testSwiftuiTwoLangsNoKeys() throws {
        let folderPath = try getFolderPath(mockName: "swiftui-twolangs")
        let xliffPaths = try getXliffFilesPaths(from: folderPath)
        let errors = try XliffValidator().validateXliffFiles(at: xliffPaths, checkEqualToKey: false)
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
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Hello, world!",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "Missing translation",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "NSHumanReadableCopyright",
                    type: .empty
                ),
                TranslationError(
                    language: "en",
                    key: "Not compiled translation",
                    type: .newMeansNoLocalized
                ),
                TranslationError(
                    language: "en",
                    key: "nsloc1",
                    type: .newMeansNoLocalized
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
                ),
                TranslationError(
                    language: "es",
                    key: "Not compiled translation",
                    type: .empty
                ),
                TranslationError(
                    language: "es",
                    key: "nsloc1",
                    type: .empty
                )
            ]
        )
    }
}

public func XCTAssertEqualDiff<T>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) throws where T : Equatable {
    let val1 = try expression1()
    let val2 = try expression2()
    if val1 == val2 {
        return
    }
    var expected: String = ""
    dump(val1, to: &expected)
    var described2: String = ""
    dump(val2, to: &described2)
    let differences = expected
        .split(separator: "\n")
        .map { String($0) }
        .difference(from: described2.split(separator: "\n").map { String($0) })
        .enumerated()
        .sorted(by: { lhs, rhs in
            lhs.offset < rhs.offset
        })
        .map { $0.element }
    XCTFail(message() + "\n" + differences
        .map {
            switch $0 {
            case .remove(_, let element, _):
                return "- " + element
            case .insert(_, let element, _):
                return "+ " + element
            }
        }
        .joined(separator: "\n"),
        file: file, line: line)
}
