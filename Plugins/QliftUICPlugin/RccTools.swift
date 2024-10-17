//
//  RccTools.swift
//  QliftUIC
//
//  Created by Dmitriy Borovikov on 14.10.2024.
//

import Foundation

func searchRCC() -> URL? {
    var pathList = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin"
    #if os(macOS)
    #if arch(arm64)
    pathList += ":/opt/homebrew/share/qt/libexec"
    #endif
    #if arch(x86_64)
    pathList += ":/usr/local/share/qt/libexec"
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
