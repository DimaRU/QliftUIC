import Foundation
import ArgumentParser

func processFile(input: URL, output: URL, verbose: Bool, localizable: Bool, strings: Bool) throws {
    let xml: Data
    do {
        xml =  try Data(contentsOf: input)
    } catch {
        print("Error read \(input.path): \(error.localizedDescription)", to: &stderror)
        throw ExitCode.failure
    }

    let parser = QliftUIParser()
    let (swiftCode, lstrings) = parser.parseUI(data: xml,
                                               fileName: output.lastPathComponent,
                                               localizable: localizable)
    guard let swiftCode = swiftCode else {
        print("XML invalid: \(input.path)", to: &stderror)
        throw ExitCode.failure
    }

    var content = ""
    
    if strings {
        for (key,value) in lstrings {
            let localizable = value.value.replacingOccurrences(of: #"""#, with: #"\""#)
            if !value.comment.isEmpty {
                content += "/* \(value) */\n"
            } else {
                content += "/* No comment provided by engineer. */\n"
            }
            content += #""\#(key)" = "\#(localizable)";\#n\#n"#
        }
    } else {
        content = """
    /********************************************************************************
    ** Code generated from UI file '\(input.lastPathComponent)'
    **
    ** Created by: Qlift User Interface Compiler version <undefined>
    **
    ** WARNING! All changes made in this file will be lost when recompiling UI file!
    ********************************************************************************/


    """
        content += swiftCode
    }

    let outputURL = output.appendingPathExtension(strings ? "strings" : "swift")
    guard !content.isEmpty else {
        print("Empty file \(output.path) is't created", to: &stderror)
        return
    }
    do {
        try content.write(to: outputURL,
                          atomically: false,
                          encoding: .utf8)
    } catch  {
        print("Write error \(output.path) \(error.localizedDescription)", to: &stderror)
        throw ExitCode.failure
    }
    if verbose {
        print("Created file \(outputURL.path)", to: &stderror)
    }
}
