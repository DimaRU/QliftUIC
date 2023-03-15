/////
////  StderrStream.swift
///   Copyright © 2022 Dmitriy Borovikov. All rights reserved.
//

import Foundation

var stderror = FileHandle.standardError

extension FileHandle: TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)
    self.write(data)
  }
}
