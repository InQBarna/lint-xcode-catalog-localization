//
//  LocalizationReport.swift
//  FMPScripts
//
//  Created by Sergi Hernanz on 27/11/24.
//

import ArgumentParser
import Foundation

struct TranslationError: Equatable {
    let language: String
    let key: String
    enum ErrorType: Equatable {
        case equalToKey
        case empty
        case newMeansNoLocalized
    }
    let type: ErrorType
    var description: String {
        switch type {
        case .equalToKey:
            return "content equal to key"
        case .empty:
            return "empty translation"
        case .newMeansNoLocalized:
            return "no localized"
        }
    }
}

class XliffValidator {
    func validateXliffFiles(at paths: [String]) -> [TranslationError] {
        let allErrors = paths.compactMap { path -> [TranslationError] in
            guard let fileName = path.components(separatedBy: "/").last,
                  let language = fileName.components(separatedBy: ".").first else {
                print("Error: Could not process file \(path)")
                return []
            }
            
            do {
                let xmlData = try Data(contentsOf: URL(fileURLWithPath: path))
                let errors = validateXliffData(xmlData, language: language)
                
                if !errors.isEmpty {
                    printErrorsForLanguage(language, errors: errors)
                } else {
                    print("✅ No errors found in \(language).xliff")
                }
                
                return errors
            } catch {
                print("Error reading file \(path): \(error.localizedDescription)")
                return []
            }
        }
        
        return allErrors.flatMap { $0 }
    }
    
    private func validateXliffData(_ data: Data, language: String) -> [TranslationError] {
        let parser = XMLParser(data: data)
        let delegate = XliffParserDelegate(language: language)
        parser.delegate = delegate
        parser.parse()
        return delegate.errors
    }
    
    private func printErrorsForLanguage(_ language: String, errors: [TranslationError]) {
        print("\n❌ Errors found in \(language).xliff:")
        for error in errors {
            print("   - Key: \(error.key)")
            print("     \(error.description)")
        }
    }
    
    func generateFinalReport(from errors: [TranslationError]) {
        print("\n📊 FINAL VALIDATION REPORT:")
        guard !errors.isEmpty else {
            print("\n✅ All translations are correct.")
            return
        }
        
        let groupedByLanguage = Dictionary(grouping: errors, by: { $0.language })
        
        for (language, languageErrors) in groupedByLanguage {
            print("\nLanguage: \(language)")
            print("Total errors: \(languageErrors.count)")
            
            let emptyTranslations = languageErrors.filter { $0.description.contains("Empty") }
            let equalToKeyTranslations = languageErrors.filter { $0.description.contains("equal to key") }
            
            print("  - Empty translations: \(emptyTranslations.count)")
            print("  - Translations equal to key: \(equalToKeyTranslations.count)")
        }
        print("")
    }
}

class XliffParserDelegate: NSObject, XMLParserDelegate {
    var errors: [TranslationError] = []
    private var currentKey: String?
    private var currentTarget = ""
    private var currentTargetState: String?
    private var currentElementName: String?
    private let language: String
    
    init(language: String) {
        self.language = language
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
        } else if trimmedTarget == key {
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

func getXliffFilesPaths(from folderPath: String) throws -> [String] {
    let folderURL = URL(fileURLWithPath: folderPath)
    let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
    let xclocDirectories = contents.filter { $0.pathExtension == "xcloc" }
    
    var xliffPaths: [String] = []
    
    for xclocDirectory in xclocDirectories {
        let localizedContentsPath = xclocDirectory.appendingPathComponent("Localized Contents")
        
        let xliffFiles = try FileManager.default.contentsOfDirectory(at: localizedContentsPath, includingPropertiesForKeys: nil)
        
        xliffPaths += xliffFiles.filter { $0.pathExtension == "xliff" }
            .map { $0.path }
    }
    
    return xliffPaths
}


struct LintLocalization: ParsableCommand {
    @Argument(help: "The path to the .xcworkspace")
    var workspaceOrProjectPath: String
    
    func run() throws {
        let uuid = UUID().uuidString
        let tempFolder = "/tmp/lint-xcode-catalog-localization-\(uuid)"
        
        defer {
            cleanupTempFolder(tempFolder)
        }
        
        do {
            try exportLocalizations(to: tempFolder)
            
            let validator = XliffValidator()
            let xliffPaths = try getXliffFilesPaths(from: tempFolder)
            
            let errors = validator.validateXliffFiles(at: xliffPaths)
            validator.generateFinalReport(from: errors)
            
            if !errors.isEmpty {
                throw ExitCode.failure
            }
        } catch {
            if (error as? ExitCode) == .failure {
                print("❌ Validation errors found")
            } else {
                print("❌ Unexpected error: \(error.localizedDescription)")
            }
            throw ExitCode.failure
        }
    }
    
    func getLocalizationLanguages(from projectPath: String) throws -> [String] {
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
        
        guard let xcstringFileURL = xcstringFiles.first else {
            throw NSError(domain: "XCStringError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No .xcstrings file found"
            ])
        }
        
        if xcstringFiles.count > 1 {
            throw NSError(domain: "XCStringError", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "More than one .xcstrings file found"
            ])
        }
        
        let data = try Data(contentsOf: xcstringFileURL)
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            var languages: Set<String> = []
            
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
            
            return Array(languages).sorted()
        }
        
        throw NSError(domain: "XCStringError", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Error parsing .xcstrings file"
        ])
    }
    
    private func exportLocalizations(to folder: String) throws {
        print("📦 Exporting localizations...")
        
        guard FileManager.default.fileExists(atPath: workspaceOrProjectPath) else {
            throw NSError(
                domain: "ExportError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "The workspace path does not exist: \(workspaceOrProjectPath)"
                ]
            )
        }
        
        do {
            let detectedLanguages = try getLocalizationLanguages(from: workspaceOrProjectPath)
            print("🌎 Detected languages: \(detectedLanguages)")
            
            let workspaceParam = workspaceOrProjectPath.contains("xcworkspace") ? "-workspace" : "-project"
            
            var arguments: [String] = [
                "-exportLocalizations",
                workspaceParam, workspaceOrProjectPath,
                "-localizationPath", folder
            ]
            
            for language in detectedLanguages {
                arguments.append(contentsOf: ["-exportLanguage", language])
            }
            
            let process = Process()
            process.launchPath = "/usr/bin/xcodebuild"
            process.arguments = arguments
            
            try runProcess(process)
            print("✅ All localizations exported successfully.")
        } catch {
            print("❌ Error retrieving languages: \(error.localizedDescription)")
        }
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
        print("🗑 Cleaning up temporary files...")
        try? FileManager.default.removeItem(atPath: folder)
        print("✅ Cleanup complete.")
    }
}

LintLocalization.main()
