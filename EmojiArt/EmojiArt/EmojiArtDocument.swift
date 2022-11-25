//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by estaife on 21/11/22.
//

import SwiftUI
import Combine

final class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    @Published private(set) var backgroundImage: UIImage?
    @Published private(set) var backgroundImageFetchStatus: BckgroundImageFetchStatus = .idle
    
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    private var autosaveTimer: Timer?
    
    enum BckgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
    }

    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    
    // MARK: - Fetch Background Image
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            downloadBackgroundImage(with: url)
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    private func downloadBackgroundImage(with url: URL) {
        let session = URLSession.shared
        let publisher = session.dataTaskPublisher(for: url)
            .map { (data, _) in UIImage(data: data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
        
        backgroundImageFetchStatus = .fetching
        backgroundImageFetchCancellable?.cancel()
        
        backgroundImageFetchCancellable = publisher
            .sink { [weak self] image in
                self?.backgroundImage = image
                self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
            }
    }
    
    // MARK: - Save Game
    private struct Autosave {
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        let thisfunction = "\(String(describing: self)).\(#function)"
        do {
            let data: Data = try emojiArt.json()
            print("\(thisfunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisfunction) success!")
        } catch let encodingError where encodingError is EncodingError {
            print("\(thisfunction) couldn't encode EmojiArt as JSON because \(encodingError.localizedDescription)")
        } catch {
            print("\(thisfunction) error = \(error)")
        }
    }
    
    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { [self] _ in
            autosave()
        }
    }
    
    // MARK: - Intent(s)
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }
    
    func addEmoji(_ text: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(text: text, at: location, size: Int(size))
    }
    
    func moveEmoji(emoji: EmojiArtModel.Emoji, at offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x = Int(offset.width)
            emojiArt.emojis[index].y = Int(offset.height)
        }
    }
    
    func scaleEmoji(emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
