import PackagePlugin
import Foundation

@main
struct UICPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {

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
                [ "--localizable",
                  "--output-directory", "\(context.pluginWorkDirectory)" ],
            inputFiles: inputFiles,
            outputFiles: outputFiles
        )
        return [command]
    }
}
