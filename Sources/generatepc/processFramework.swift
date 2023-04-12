/////
////  processFramework.swift
///   Created by Dmitriy Borovikov on 11.04.2023.
//

import Foundation


func processFramework(qtURL: URL, frameworkURL: URL) -> (String, String)? {
    let frameworkName = frameworkURL.deletingPathExtension().lastPathComponent
    let prlPath = frameworkURL.appendingPathComponent("Resources/\(frameworkName).prl")
    let prlContents: String
    do {
        prlContents = try String(contentsOf: prlPath)
    } catch {
        print("Can't read: \(prlPath.path): \(error.localizedDescription)", to: &stderror)
        return nil
    }
    
    var prlDict: [String: String] = [:]
    prlContents.split(separator: "\n").map{ $0.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true) }
        .forEach{
            prlDict[String($0[0].dropLast(1))] = String($0[1].dropFirst(1))
    }
    
    guard
        let version = prlDict["MAKE_PRL_VERSION"] ?? prlDict["QMAKE_PRL_VERSION"]
    else {
        print("Wrong .prl file: \(prlPath.path)", to: &stderror)
        return nil
    }
    
    let libs = prlDict["MAKE_PRL_LIBS"] ?? prlDict["QMAKE_PRL_LIBS"] ?? ""
    let frameworkDeps = Set<String>(libs.split(separator: "-").filter{ $0.hasPrefix("framework Qt")}.map{ $0.dropFirst(12).trimmingCharacters(in: .whitespacesAndNewlines) })

    let pc = """
prefix=\(qtURL.path)
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/lib/\(frameworkName).framework/Headers

Name: Qt6 \(frameworkName.dropFirst(2))
Version: \(version)
Libs: -F${libdir} -framework \(frameworkName)
Cflags: -I${includedir} -I${prefix}/include -F${libdir}
Requires:\(frameworkDeps.reduce("", {$0 + " Qt6" + $1}))

"""
    return (pc, frameworkName)
}
