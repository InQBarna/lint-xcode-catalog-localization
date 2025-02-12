//
//  LocalizationReport.swift
//  FMPScripts
//
//  Created by Sergi Hernanz on 27/11/24.
//

import ArgumentParser
import Foundation

struct TranslationError: Error, Equatable {
    let language: String
    let key: String
    enum ErrorType: Equatable {
        case equalToKey
        case empty
        case newMeansNoLocalized
        
        var description: String {
            switch self {
            case .equalToKey:
                return "content equal to key"
            case .empty:
                return "empty translation"
            case .newMeansNoLocalized:
                return "no localized"
            }
        }
        var warn_description: String {
            switch self {
            case .equalToKey:
                return "content_equal_to_key"
            case .empty:
                return "empty_translation"
            case .newMeansNoLocalized:
                return "no_localized"
            }
        }
    }
    let type: ErrorType
}

enum LintLocalizationError: Error {
    case fileWithInvalidExtension(URL)
}

class XliffValidator {
    func validateXliffFiles(at urls: [URL], checkEqualToKey: Bool) throws -> [TranslationError] {
        try urls.flatMap { url -> [TranslationError] in
            guard let language = url.lastPathComponent.components(separatedBy: ".").first else {
                throw LintLocalizationError.fileWithInvalidExtension(url)
            }
            return validateXliffData(
                try Data(contentsOf: url),
                language: language,
                checkEqualToKey: checkEqualToKey
            )
        }
    }
    
    private func validateXliffData(_ data: Data, language: String, checkEqualToKey: Bool) -> [TranslationError] {
        let parser = XMLParser(data: data)
        let delegate = XliffParserDelegate(language: language, checkEqualToKey: checkEqualToKey)
        parser.delegate = delegate
        parser.parse()
        return delegate.errors
    }
}

class XliffParserDelegate: NSObject, XMLParserDelegate {
    var errors: [TranslationError] = []
    private var currentKey: String?
    private var currentTarget = ""
    private var currentTargetState: String?
    private var currentElementName: String?
    private let language: String
    private let checkEqualToKey: Bool
    
    init(language: String, checkEqualToKey: Bool) {
        self.language = language
        self.checkEqualToKey = checkEqualToKey
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
        
        if elementName == "trans-unit" {
            currentKey = attributeDict["id"]
            currentTarget = ""
            currentTargetState = nil
        }
        if elementName == "target" {
            currentTargetState = attributeDict["state"]
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElementName == "target" else { return }
        currentTarget += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elementName == "trans-unit", let key = currentKey else { return }
        
        let trimmedTarget = currentTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTargetState = currentTargetState?.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTarget.isEmpty {
            errors.append(TranslationError(language: language, key: key, type: .empty))
        } else if trimmedTarget == key && checkEqualToKey {
            errors.append(TranslationError(language: language, key: key, type: .equalToKey))
        } else if trimmedTargetState == "new" {
            errors.append(TranslationError(language: language, key: key, type: .newMeansNoLocalized))
        }
        
        currentKey = nil
        currentTarget = ""
        currentTargetState = ""
        currentElementName = nil
    }
}

func getXliffFilesPaths(from folderPath: String) throws -> [URL] {
    let folderURL = URL(fileURLWithPath: folderPath)
    let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
    let xclocDirectories = contents.filter { $0.pathExtension == "xcloc" }
    return try xclocDirectories.flatMap { xclocDirectory in
        let localizedContentsPath = xclocDirectory.appendingPathComponent("Localized Contents")
        let xliffFiles = try FileManager.default.contentsOfDirectory(at: localizedContentsPath, includingPropertiesForKeys: nil)
        return xliffFiles.filter { $0.pathExtension == "xliff" }
    }
}

struct LintLocalization: ParsableCommand {
    @Argument(help: "The path to the .xcodeproj or .xcworkspace")
    var workspaceOrProjectPath: String
    
    @Flag(inversion: .prefixedNo, help: "Indicates whether to use string keys (default) or base localization identifiers. Use '--no-keys' if you don't use keys.")
    var keys: Bool = true
    
    func run() throws {
        let uuid = UUID().uuidString
        let tempFolder = "/tmp/lint-xcode-catalog-localization-\(uuid)"
        
        defer {
            print("🗑 Cleaning up temporary files...")
            cleanupTempFolder(tempFolder)
            print("✅ Cleanup complete.")
        }
        
        let detectedWithinXcodeBuildEnvironment = nil != ProcessInfo.processInfo.environment["SOURCE_ROOT"]
        let errors: [TranslationError]
        do {
            
            print("🌎 Checking project for languages")
            let xcstringFiles = try getXCStringFiles(from: workspaceOrProjectPath)
            let detectedLanguages = try getLocalizationLanguages(xcstringFiles: xcstringFiles)
            print("🌎 Detected languages: \(detectedLanguages)")
            
            if detectedWithinXcodeBuildEnvironment {
                print("🗓️ Validating localizations")
                errors = try validate(
                    languages: detectedLanguages,
                    xcstringFiles: xcstringFiles
                )
            } else {
                print("📦 Exporting localizations...")
                try exportLocalizations(to: tempFolder, languages: detectedLanguages)
                print("✅ All localizations exported successfully.")
                print("🗓️ Validating localizations")
                let validator = XliffValidator()
                let xliffPaths = try getXliffFilesPaths(from: tempFolder)
                errors = try validator.validateXliffFiles(at: xliffPaths, checkEqualToKey: keys)
            }
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
        guard errors.isEmpty else {
            let errorsReport: [String]
            if detectedWithinXcodeBuildEnvironment {
                errorsReport = generateCompilerErrorReport(from: errors)
            } else {
                errorsReport = generateHumanErrorReport(from: errors)
            }
            errorsReport.forEach { reportLine in
                print("\(reportLine)")
            }
            throw ExitCode.failure
        }
        
        print("✅ All translations are correct.")
    }
    
    func getXCStringFiles(from projectPath: String) throws -> [URL] {
        let projectURL = URL(fileURLWithPath: projectPath)
        let projectFolder = projectURL.deletingLastPathComponent()
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: projectFolder, includingPropertiesForKeys: nil)
        
        var xcstringFiles: [URL] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "xcstrings" {
                xcstringFiles.append(fileURL)
            }
        }
        
        guard xcstringFiles.count > 0 else {
            throw NSError(domain: "XCStringError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No .xcstrings file found"
            ])
        }
        return xcstringFiles
    }
        
    func getLocalizationLanguages(xcstringFiles: [URL]) throws -> [String] {
        var languages: Set<String> = []
        for xcstringFileURL in xcstringFiles {
            let data = try Data(contentsOf: xcstringFileURL)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NSError(domain: "XCStringError", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Error parsing .xcstrings file \(xcstringFileURL)"
                ])
            }
            if let strings = json["strings"] as? [String: Any] {
                for (_, value) in strings {
                    if let localizedStrings = value as? [String: Any],
                       let localizations = localizedStrings["localizations"] as? [String: Any] {
                        languages.formUnion(localizations.keys)
                    }
                }
            }
            if let sourceLanguage = json["sourceLanguage"] as? String {
                languages.insert(sourceLanguage)
            }
        }
        
        guard languages.count > 0 else {
            throw NSError(domain: "XCStringError", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "No languages found"
            ])
        }
    
        return Array(languages).sorted()
    }
    
    func validate(languages: [String], xcstringFiles: [URL]) throws -> [TranslationError] {
        let jsons: [[String: Any]] = try xcstringFiles.map { xcstringFileURL in
            let data = try Data(contentsOf: xcstringFileURL)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NSError(domain: "XCStringError", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Error parsing .xcstrings file \(xcstringFileURL)"
                ])
            }
            return json
        }
        return jsons.flatMap { (json) -> [TranslationError] in
            (json["strings"] as? [String: Any] ?? [:]).flatMap { (key, value) -> [TranslationError] in
                let localizations = (value as? [String: Any])?["localizations"] as? [String: Any] ?? [:]
                return languages.compactMap { lang in
                    guard let currentLangLoc = localizations[lang] as? [String: Any],
                          let stringUnit = currentLangLoc["stringUnit"] as? [String: Any],
                          let stringUnitValue = stringUnit["value"] as? String else {
                        return TranslationError(
                            language: lang,
                            key: key,
                            type: .empty
                        )
                    }
                    if stringUnitValue.isEmpty {
                        return TranslationError(
                            language: lang,
                            key: key,
                            type: .empty
                        )
                    } else if stringUnitValue == key {
                        return TranslationError(
                            language: lang,
                            key: key,
                            type: .equalToKey
                        )
                    } else {
                        return nil
                    }
                }
            }
        }
    }
    
    private func exportLocalizations(to folder: String, languages: [String]) throws {
        
        guard FileManager.default.fileExists(atPath: workspaceOrProjectPath) else {
            throw NSError(
                domain: "ExportError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "The workspace path does not exist: \(workspaceOrProjectPath)"
                ]
            )
        }
        
        let workspaceParam = workspaceOrProjectPath.contains("xcworkspace") ? "-workspace" : "-project"
        
        var arguments: [String] = [
            "-exportLocalizations",
            workspaceParam, workspaceOrProjectPath,
            "-localizationPath", folder
        ]
        
        for language in languages {
            arguments.append(contentsOf: ["-exportLanguage", language])
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/xcodebuild"
        process.arguments = arguments
        
        try runProcess(process)
    }
    
    private func runProcess(_ process: Process) throws {
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        let stdOutPipe = Pipe()
        process.standardOutput = stdOutPipe

        var errorData = Data()
        DispatchQueue(label: "process-error", qos: .userInitiated).async {
            errorData.append(errorPipe.fileHandleForReading.readDataToEndOfFile())
        }
        DispatchQueue(label: "process-stdout", qos: .userInitiated).async {
            stdOutPipe.fileHandleForReading.readDataToEndOfFile()
        }
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "XcodeBuildError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
    }
    
    private func cleanupTempFolder(_ folder: String) {
        try? FileManager.default.removeItem(atPath: folder)
    }
        
    struct ErrorReportByType {
        let type: TranslationError.ErrorType
        let languages: [String]
        let key: String
    }
    func generateErrorsReportByType(from errors: [TranslationError]) -> [ErrorReportByType] {
        Dictionary(grouping: errors, by: { $0.key })
            .flatMap { key, errorsGroupedByKey in
                Dictionary(grouping: errorsGroupedByKey, by: { $0.type })
                    .compactMap { (errorType, errorsGroupedByErrorType) -> ErrorReportByType? in
                        ErrorReportByType(
                            type: errorType,
                            languages: errorsGroupedByErrorType.map { $0.language },
                            key: key
                        )
                    }
            }
    }
    
    func generateHumanErrorReport(from errors: [TranslationError]) -> [String] {
        generateErrorsReportByType(from: errors)
            .map { error in
                "❌ Error: key \"\(error.key)\" has \(error.type.description) for languages (\(error.languages.joined(separator: ","))) "
            }
    }
    
    func generateCompilerErrorReport(from errors: [TranslationError]) -> [String] {
        generateErrorsReportByType(from: errors)
            .map { error in
                "warning:\(error.type.warn_description):\(error.languages.joined(separator: ",")):\"\(error.key)\""
            }
    }

}

LintLocalization.main()
