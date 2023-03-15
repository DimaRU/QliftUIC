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

    @Option(name: .shortAndLong, help: ArgumentHelp("The output path for generated .swift files.",
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
            print("Can't create output directory \(outputURL.path): \(error.localizedDescription)")
            throw ExitCode.failure
        }
        
        for input in file {
            let outputFile = input.deletingPathExtension().appendingPathExtension("swift").lastPathComponent
            let output = outputURL.appendingPathComponent(outputFile)
            try processFile(input: input, output: output, verbose: verbose)
        }
    }
}
