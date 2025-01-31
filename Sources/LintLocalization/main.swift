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
    let description: String
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
        
        return delegate.errors.map { error in
            TranslationError(
                language: language,
                key: error.key,
                description: error.description
            )
        }
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
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard currentElementName == "target" else { return }
        currentTarget += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "trans-unit", let key = currentKey {
            let trimmedTarget = currentTarget.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedTarget.isEmpty {
                errors.append(TranslationError(language: language, key: key, description: "Empty translation"))
            } else if trimmedTarget == key {
                errors.append(TranslationError(language: language, key: key, description: "Translation equal to key"))
            }
            
            currentKey = nil
            currentTarget = ""
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
    @Argument(help: "The path to the folder containing .xcloc directories")
    var folderPath: String
    
    func run() throws {
        let validator = XliffValidator()
        
        do {
            let xliffPaths = try getXliffFileNames(from: folderPath)
            
            let errors = validator.validateXliffFiles(at: xliffPaths)
            validator.generateFinalReport(from: errors)
            
            if errors.count > 0 {
                throw ExitCode.failure
            }
        } catch {
            if let exitByCode = error as? ExitCode,
               exitByCode == .failure {
                throw ExitCode.failure
            } else {
                print("Error linting: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }
    }
}

LintLocalization.main()
