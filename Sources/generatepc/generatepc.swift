/////
////  generatepc.swift
///   Copyright © 2023 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import ArgumentParser

@main
struct generatepc: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "generatepc",
                                                    abstract: "Generate pkg-config files for macOS Qt6.",
                                                    version: "0.0.1")
    @Argument(help: "Qt installation path.", transform: { URL(fileURLWithPath: $0) })
    var qtPath: URL

    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose = false

    @Option(name: .shortAndLong,
            help: ArgumentHelp("The output path for generated files.",
            discussion: "By default generated files written to current directory.",
            valueName: "path"),
            transform: { URL(fileURLWithPath: $0) }
    )
    var outputDirectory: URL?


    mutating func run() throws {
        let fileManager = FileManager.default
        let outputPath = outputDirectory ?? qtPath.appendingPathComponent("lib/pkgconfig", isDirectory: true)
        do {
            try fileManager.createDirectory(at: outputPath, withIntermediateDirectories: true)
        } catch {
            print("Can't create output directory \(outputPath.path): \(error.localizedDescription)", to: &stderror)
            throw ExitCode.failure
        }
        
        let frameworkList: [URL]
        let libPath = qtPath.appendingPathComponent("lib")
        do {
            frameworkList = try fileManager.contentsOfDirectory(at: libPath, includingPropertiesForKeys: []).filter{ $0.pathExtension == "framework"}
            
        } catch  {
            print("Can't get directory contents: \(libPath): \(error.localizedDescription)", to: &stderror)
            throw ExitCode.failure
        }
        guard !frameworkList.isEmpty else {
            print("No frameworks found at: \(libPath)", to: &stderror)
            throw ExitCode.failure
        }
        
        for framework in frameworkList {
            guard let (content, name) = processFramework(qtURL: qtPath, frameworkURL: framework) else { continue }
            let outputURL = outputPath.appendingPathComponent("Qt6\(name.dropFirst(2)).pc")
            do {
                try content.write(to: outputURL,
                                  atomically: false,
                                  encoding: .utf8)
            } catch  {
                print("Write error \(outputURL.path) \(error.localizedDescription)", to: &stderror)
                throw ExitCode.failure
            }
            if verbose {
                print("Generated file \(outputURL.path)")
            }
            
        }
    }
}
