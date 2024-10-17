import PackagePlugin
import Foundation

@main
struct UICPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        var commands: [Command] = []
        try commands.append(contentsOf: UICommand(context: context, target: target))
        try commands.append(contentsOf: RCCCommand(context: context, target: target))
        return commands
    }
    
    func UICommand(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        let inputFiles = target.sourceFiles(withSuffix: "ui").map{ $0.path }
        guard !inputFiles.isEmpty else { return [] }
        let outputFiles = inputFiles.map { context.pluginWorkDirectory.appending($0.stem + ".swift") }
        let outputList = outputFiles.map { $0.stem + ".swift" }.joined(separator: " ")
        
        let command = Command.buildCommand(
            displayName:
                "Generating \(outputList) in \(context.pluginWorkDirectory)",
            executable:
                try context.tool(named: "qlift-uic").path,
            arguments:
                (inputFiles.map { $0.string }) +
            [ "--code",
              "--output-directory", "\(context.pluginWorkDirectory)" ],
            inputFiles: inputFiles,
            outputFiles: outputFiles
        )
        return [command]
    }
    
    func RCCCommand(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        let qrcFiles = target.sourceFiles(withSuffix: "qrc").map{ $0.path }
        guard !qrcFiles.isEmpty else { return [] }
        guard let rccURL = searchRCC() else {
            Diagnostics.error("rcc not found in PATH")
            return []
        }
        let parser = QrcParser()
        
        return try qrcFiles.compactMap { qrcFile in
            let qrc = try Data(contentsOf: URL(fileURLWithPath: qrcFile.string))
            guard var inputFiles = parser.parseQrc(qrc: qrc, fileName: qrcFile.string) else {
                Diagnostics.error("Can't parce \(qrcFile.stem)")
                return nil
            }
            inputFiles.append(qrcFile.string)
            let outputFile = context.pluginWorkDirectory.appending(qrcFile.stem + ".rcc")
            
            return Command.buildCommand(
                displayName:
                    "Generating \(outputFile)",
                executable:
                        .init(rccURL.path),
                arguments:
                    [ qrcFile,
                      "--binary",
                      "--output",
                      outputFile.string ],
                inputFiles: inputFiles.map{ Path($0) },
                outputFiles: [outputFile]
            )
        }
    }
}
