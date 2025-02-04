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
            return "empty tranlation"
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
        if elementName == "trans-unit", let key = currentKey {
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
}

func getXliffFileNames(from folderPath: String) throws -> [String] {
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
    var workspacePath: String
    
    func run() throws {
        let tempFolder = "tmp_xcloc_export"
        
        defer { cleanupTempFolder(tempFolder) }
        
        do {
            try exportLocalizations(to: tempFolder)
            
            let validator = XliffValidator()
            let xliffPaths = try getXliffFileNames(from: tempFolder)
            
            let errors = validator.validateXliffFiles(at: xliffPaths)
            validator.generateFinalReport(from: errors)
            
            if !errors.isEmpty {
                throw ExitCode.failure
            }
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
    
    private func exportLocalizations(to folder: String) throws {
        print("📦 Exporting localizations...")
        
        guard FileManager.default.fileExists(atPath: workspacePath) else {
            throw NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "The workspace path does not exist: \(workspacePath)"])
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/xcodebuild"
        process.arguments = [
            "-exportLocalizations",
            "-workspace", workspacePath,
            "-localizationPath", folder,
            "-exportLanguage", "es",
            "-exportLanguage", "ca",
            "-exportLanguage", "en",
        ]
        
        try runProcess(process)
        print("✅ Localizations exported successfully.")
    }
    
    private func runProcess(_ process: Process) throws {
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        let errorHandle = errorPipe.fileHandleForReading
        var errorData = Data()
        
        let errorQueue = DispatchQueue(label: "process-error", qos: .userInitiated)
        errorQueue.async {
            errorData.append(errorHandle.readDataToEndOfFile())
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
