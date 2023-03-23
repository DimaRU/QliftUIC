/////
////  qlift-uic.swift
///   Copyright © 2022 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct QliftUIC: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "qlift-uic",
                                                    abstract: "Generate Swift code from Qt5 user interfaces.",
                                                    version: "0.0.1")
    @Argument(help: "UI file to compile.", transform: { URL(fileURLWithPath: $0) })
    var file: [URL]

    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose = false

    enum OutputBehaviour: String, EnumerableFlag {
        case code, localizable, strings, `extension`
    }

    @Flag(exclusivity: .exclusive,
          help: .init("Output Behaviour",
          discussion: """
            Explanation:
            --code: Generate UI code
            --localizable: Generate localizable UI code
            --strings: Generate .strings files
            --extension: Generate localization resource accessor extension
            """))
    var outputBehaviour: OutputBehaviour = .code
          
    @Option(name: .shortAndLong,
            help: ArgumentHelp("The output path for generated files.",
            discussion: "By default generated files written to current directory.",
            valueName: "path"))
    var outputDirectory: String?


    mutating func run() throws {
        let fileManager = FileManager.default
        let outputPath = outputDirectory ?? fileManager.currentDirectoryPath
        let outputURL = URL(fileURLWithPath: outputPath)

        for input in file {
            guard input.pathExtension == "ui" else {
                throw ValidationError("File \(input.path) must have extension 'ui'")
            }
        }
        
        do {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)
        } catch {
            print("Can't create output directory \(outputURL.path): \(error.localizedDescription)", to: &stderror)
            throw ExitCode.failure
        }
        
        if outputBehaviour == .extension {
            try generateExtensionFile(outputDir: outputURL, verbose: verbose)
            return
        }
        for input in file {
            let outputFile = input.deletingPathExtension().lastPathComponent
            let output = outputURL.appendingPathComponent(outputFile)
            try processFile(input: input,
                            output: output,
                            verbose: verbose,
                            localizable: outputBehaviour == .localizable,
                            strings: outputBehaviour == .strings)
        }
    }
    
    func generateExtensionFile(outputDir: URL, verbose: Bool) throws {
        let content = """
import Foundation

@inlinable
func QTLocalizedString(_ s: String, tableName: String?, comment: String) -> String {
    NSLocalizedString(s, tableName: tableName, bundle: Bundle.lang, comment: comment)
}

extension Bundle {
    @usableFromInline
    static let lang: Bundle = {
        let lang = Locale.current.languageCode ?? "en"
        guard
            let path = Bundle.module.path(forResource: lang, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            fatalError("could not load language bundle")
        }
        return bundle
    }()
}
"""

        let outputURL = outputDir.appendingPathComponent("language_bundle_accessor.swift")

        do {
            try content.write(to: outputURL,
                              atomically: false,
                              encoding: .utf8)
        } catch  {
            print("Write error \(outputURL.absoluteString) \(error.localizedDescription)", to: &stderror)
            throw ExitCode.failure
        }
        if verbose {
            print("Created file \(outputURL.path)")
        }
    }
}
