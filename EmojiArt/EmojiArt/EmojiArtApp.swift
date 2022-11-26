//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by estaife on 21/11/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject
    var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore)
        }
    }
}
