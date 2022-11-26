//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by estaife on 21/11/22.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "lima.estaife.cs193p.emojiart")
}

final class EmojiArtDocument: ReferenceFileDocument {
    
    // MARK: - Publishers
    @Published
    private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    @Published
    private(set) var backgroundImage: UIImage?
    
    @Published
    private(set) var backgroundImageFetchStatus: BckgroundImageFetchStatus = .idle
    
    // MARK: - Properties
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    private var backgroundImageFetchCancellable: AnyCancellable?
    static var readableContentTypes = [UTType.emojiart]
    static var writeableContentTypes = [UTType.emojiart]
    
    // MARK: - Inits
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    init() {
        emojiArt = EmojiArtModel()
    }
           
    // MARK: - Fetch Background Image
    enum BckgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }

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
    
    // MARK: - ReferenceFileDocument Methods
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    // MARK: - Intent(s)
    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablePerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
        }
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablePerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(text: emoji, at: location, size: Int(size))
        }
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, at offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablePerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x = Int(offset.width)
                emojiArt.emojis[index].y = Int(offset.height)
            }
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablePerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    // MARK: - Undo
    private func undoablePerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { mySelf in
            mySelf.undoablePerform(operation: operation, with: undoManager) {
                mySelf.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(operation)
    }
}
