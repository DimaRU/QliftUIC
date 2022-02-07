import Foundation
import ArgumentParser

func processFile(input: URL, output: URL, verbose: Bool) throws {
    let xml: Data
    do {
        xml =  try Data(contentsOf: input)
    } catch {
        print("Error read \(input.path): \(error.localizedDescription)")
        throw ExitCode.failure
    }

    let parser = QliftUIParser()
    guard let ui = parser.parseUI(data: xml) else {
        print("XML invalid: \(input.path)")
        throw ExitCode.failure
    }
    
    var content = """
    /********************************************************************************
    ** Form generated from reading UI file '\(input.lastPathComponent)'
    **
    ** Created by: Qlift User Interface Compiler version <undefined>
    **
    ** WARNING! All changes made in this file will be lost when recompiling UI file!
    ********************************************************************************/


    """
    content += ui

    do {
        try content.write(to: output, atomically: false, encoding: .utf8)
    } catch  {
        print("Write error \(output.path) \(error.localizedDescription)")
        throw ExitCode.failure
    }
    if verbose {
        print("Created file \(output.path)")
    }
}
