import PackagePlugin
import Foundation

@main
struct GeneratePCPlugin: CommandPlugin {

    func performCommand(context: PluginContext, arguments: [String]) throws {
        let uicTool = try context.tool(named: "generatepc").path
        let process = try Process.run(URL(fileURLWithPath: uicTool.string), arguments: arguments)
        process.waitUntilExit()
        
        guard
            process.terminationReason == .exit,
            process.terminationStatus == 0
        else {
            let problem = "\(process.terminationReason):\(process.terminationStatus)"
            Diagnostics.error("generatepc invocation failed: \(problem)")
            return
        }
    }
}
