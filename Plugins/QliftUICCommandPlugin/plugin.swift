import PackagePlugin
import Foundation

@main
struct UicCmdPlugin: CommandPlugin {
    enum OutputBehaviour: String, CaseIterable {
        case code, localizable, strings, `extension`
    }

    private func runTool(context: PluginContext, arguments: [String]) throws -> Bool {
        let uicTool = try context.tool(named: "qlift-uic").path
        let process = try Process.run(URL(fileURLWithPath: uicTool.string), arguments: arguments)
        process.waitUntilExit()
        
        if process.terminationReason == .exit && process.terminationStatus == 0 {
            return true
        } else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("qlift-uic invocation failed: \(problem)")
            return false
        }
    }

    func performStringsCommand(context: PluginContext,
                               targets: [Target],
                               arguments: [String]
    ) throws {
        for target in targets {
            guard let target = target as? SourceModuleTarget else { continue }
            let fileList = target.sourceFiles(withSuffix: "ui").map { $0.path.string }
            guard !fileList.isEmpty else { continue }
            
            let outputDir = target.directory.appending(["Resources", "base.lproj"]).string
            var runArgs = fileList
            runArgs += ["--output-directory", outputDir]
            runArgs += arguments

            if try runTool(context: context, arguments: runArgs) {
                print("Generated .strings at \(outputDir).")
            }
        }
    }

    
    func performCodeCommand(context: PluginContext,
                            targets: [Target],
                            arguments: [String]
    ) throws {
        for target in targets {
            guard let target = target as? SourceModuleTarget else { continue }
            let fileList = target.sourceFiles(withSuffix: "ui").map { $0.path.string }
            guard !fileList.isEmpty else { continue }

            let outputDir = context.pluginWorkDirectory.appending(target.name).string
            var runArgs = fileList
            runArgs += ["--output-directory", outputDir]
            runArgs += arguments

            if try runTool(context: context, arguments: runArgs) {
                print("Generated UI code at \(outputDir).")
            }
        }
    }
    
    func performExtCommand(context: PluginContext,
                            targets: [Target],
                            arguments: [String]
    ) throws {
        for target in targets {
            guard let target = target as? SourceModuleTarget else { continue }
            let fileList = target.sourceFiles(withSuffix: "ui").map { $0.path.string }
            guard !fileList.isEmpty else { continue }

            let outputDir = target.directory.string
            var runArgs = ["--output-directory", outputDir]
            runArgs += arguments

            if try runTool(context: context, arguments: runArgs) {
                print("Code generated at \(outputDir).")
            }
        }
    }

    func performCommand(context: PluginContext, arguments: [String]) throws {
        var outputBehaviour: OutputBehaviour?
        var argExtractor = ArgumentExtractor(arguments)
        let targetNames = argExtractor.extractOption(named: "target")
        let targets = targetNames.isEmpty
            ? context.package.targets
            : try context.package.targets(named: targetNames)
        let remainingArguments = argExtractor.remainingArguments
        for flag in OutputBehaviour.allCases {
            if argExtractor.unextractedOptionsOrFlags.contains("--" + flag.rawValue) {
                outputBehaviour = flag
                break
            }
        }
        guard let outputBehaviour = outputBehaviour else {
            Diagnostics.error("One of the flags must be specified: --code/--localizable/--strings/--extension")
            return
        }
        switch outputBehaviour {
        case .code, .localizable:
            try performCodeCommand(context: context, targets: targets, arguments: remainingArguments)
        case .strings:
            try performStringsCommand(context: context, targets: targets, arguments: remainingArguments)
        case .extension:
            try performExtCommand(context: context, targets: targets, arguments: remainingArguments)
        }
    }
}
