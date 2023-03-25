import PackagePlugin
import Foundation

@main
struct RccCommandPlugin: CommandPlugin {
    private func searchRCC() -> URL? {
        var pathList = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin"
        #if os(macOS)
        #if arch(arm64)
        pathList += ":/opt/homebrew/share/qt/libexec"
        #endif
        #if arch(x86_64)
        pathList += ":/usr/share/qt/libexec"
        #endif
        #endif
        for path in pathList.split(separator: ":") {
            let url = URL(fileURLWithPath: String(path)).appendingPathComponent("rcc")
            if let res = try? url.resourceValues(forKeys: [.isExecutableKey]),
               res.isExecutable ?? false
            {
                return url
            }
        }
        return nil
    }

    private func runTool(arguments: [String]) throws -> Bool {
        guard let rccURL = searchRCC() else {
            Diagnostics.error("rcc not found in PATH")
            return false
        }
        let process = try Process.run(rccURL, arguments: arguments)
        process.waitUntilExit()
        
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            return true
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("rcc invocation failed: \(problem)")
            return false
        }
    }
    
    func searchQRC(in directory: String) -> URL? {
        let manager = FileManager.default
        let resourceKeys = Set<URLResourceKey>([.nameKey, .pathKey])
        let enumerator = manager.enumerator(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
        
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "qrc" {
            return fileURL
        }
        return nil
    }
    
    func performCommand(context: PluginContext,
                        targets: [Target],
                        arguments: [String]
    ) throws {
        for target in targets {
            guard let target = target as? SourceModuleTarget else { continue }
            guard let qrcURL = searchQRC(in: target.directory.string) else { return }
            let stem = qrcURL.deletingPathExtension().lastPathComponent

            let outputPath = target.directory.appending("Resources").appending(stem + ".rcc")

            var runArgs = [qrcURL.path]
            runArgs += ["--binary"]
            runArgs += ["--output", outputPath.string]
            runArgs += arguments

            if try runTool(arguments: runArgs) {
                print("Created \(outputPath.string)")
            }
            let accessor = """
////
///  qt_resource_accessor.swift
//

import Qlift
import Foundation

extension Bundle {
    
    class func registerResource() {
        guard
            let rccFilename = Bundle.module.path(forResource: "\(stem)", ofType: "rcc"),
            QResource.registerResource(rccFilename: rccFilename)
        else {
            fatalError("Can't load resources")
        }
    }

}
"""
            let accessorPath = target.directory.appending("qt_resource_accessor.swift").string
            try accessor.write(to: URL(fileURLWithPath: accessorPath), atomically: true, encoding: .utf8)
            print("Created \(accessorPath)")
        }
    }

    func performCommand(context: PluginContext, arguments: [String]) throws {
        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targets = targetNames.isEmpty
            ? context.package.targets
            : try context.package.targets(named: targetNames)
        try performCommand(context: context, targets: targets, arguments: arguments)
    }
}
