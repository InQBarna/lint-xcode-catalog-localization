//
//  LocalizationReport.swift
//  FMPScripts
//
//  Created by Sergi Hernanz on 27/11/24.
//

import Foundation

struct TranslationError {
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
    let contents = try FileManager.default.contentsOfDirectory(atPath: folderPath)
    let xclocDirectories = contents.filter { $0.hasSuffix(".xcloc") }
    var xliffPaths: [String] = []
    
    for xclocDirectory in xclocDirectories {
        let xclocPath = folderPath + xclocDirectory + "/Localized Contents/"
        let xliffFiles = try FileManager.default.contentsOfDirectory(atPath: xclocPath)
        
        xliffPaths += xliffFiles.filter { $0.hasSuffix(".xliff") }
            .map { xclocPath + $0 }
    }
    
    return xliffPaths
}

func main() {
    let arguments = CommandLine.arguments
    guard arguments.count > 1 else {
        print("Error: Se debe proporcionar el path de la carpeta.")
        exit(-1)
    }
    
    let folderPath = arguments[1]
    let validator = XliffValidator()
    
    do {
        let xliffPaths = try getXliffFileNames(from: folderPath)
        
        let errors = validator.validateXliffFiles(at: xliffPaths)
        validator.generateFinalReport(from: errors)
        if errors.count > 0 {
	    exit(-1)
        }
    } catch {
        print("Error al obtener los archivos .xliff: \(error.localizedDescription)")
	exit(-1)
    }
}

main()
