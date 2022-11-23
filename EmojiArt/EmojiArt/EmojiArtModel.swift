//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by estaife on 21/11/22.
//

import Foundation

struct EmojiArtModel: Codable {
    var background: Background = .blank
    var emojis = [Emoji]()
    
    private var uniqueEmojiId = 0
    
    init() { }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    struct Emoji: Codable, Identifiable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    func json() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    mutating func addEmoji(text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}
