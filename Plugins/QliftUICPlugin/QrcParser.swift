/////
////  QrcParser.swift
///   Copyright © 2024 Dmitriy Borovikov. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

class QrcParser: NSObject {
    var fileList: [String] = []
    var currentElement: String?
    var fileName = ""
    
    public func parseQrc(qrc: Data, fileName: String) -> [String]? {
        self.fileName = fileName

        let parser = XMLParser(data: qrc)
        parser.delegate = self
        
        guard parser.parse() else { return nil }
        
        let rootDirectory = URL(fileURLWithPath: fileName).deletingLastPathComponent()
        return fileList.map {
            rootDirectory.appendingPathComponent($0, isDirectory: false).path
        }
    }
}

extension QrcParser: XMLParserDelegate {
    public func parserDidStartDocument(_ parser: XMLParser) {
        currentElement = ""
        fileList = []
    }
    
    public func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if element == "file" {
            currentElement = ""
        } else {
            currentElement = nil
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
        guard let currentElement else { return }
        fileList.append(currentElement)
        self.currentElement = nil
    }
    
    public func parser(_ parser: XMLParser, foundCharacters: String) {
        guard currentElement != nil else { return }
        currentElement! += foundCharacters
    }
}
