//
//  LintLocalizationTests.swift
//  lint-xcode-catalog-localization
//
//  Created by Sergi Hernanz on 31/1/25.
//


import XCTest
@testable import LintLocalization

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
                description: "Empty translation"
            )
        )
    }
}
