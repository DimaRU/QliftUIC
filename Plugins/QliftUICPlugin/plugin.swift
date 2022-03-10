import PackagePlugin
import Foundation

@main
struct UICPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
       
        guard let target = target as? SourceModuleTarget else { return [] }
        return try target.sourceFiles.filter{ $0.path.extension == "ui"}.map {
            let outputName = $0.path.stem + ".swift"
            let outputPath = context.pluginWorkDirectory.appending(outputName)
            return .buildCommand(
                displayName:
                    "Generating \(outputName) from \($0.path.lastComponent)",
                executable:
                    try context.tool(named: "qlift-uic").path,
                arguments: [ "\($0.path)", "-o", "\(context.pluginWorkDirectory)" ],
                inputFiles: [ $0.path ],
                outputFiles: [ outputPath ]
            )
        }
    }
}
