//
//  OPMLDocument.swift
//  Sources
//
//  Created on November 26, 2025.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let opml = UTType(importedAs: "org.opml.opml", conformingTo: .xml)
}

struct OPMLDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.opml, .xml] }
    static var writableContentTypes: [UTType] { [.opml] }
    
    var content: String
    
    init(content: String = "") {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
