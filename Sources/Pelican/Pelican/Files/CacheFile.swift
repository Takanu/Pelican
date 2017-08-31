
import Foundation
import Vapor


/** Represents a file that has been uploaded and is stored in the cache for.
 */
struct CacheFile {
  private enum File {
    case audio(Audio)
    case document(Document)
    case photo(Photo)
    case sticker(Sticker)
    case video(Video)
    case voice(Voice)
  }
  
  private var file: File
  /// The time at which it was uploaded.
  var uploadTime: Int
  /// The file upload type that was used to upload it.
  var uploadData: FileLink
  
  var getFile: MessageContent {
    switch file {
    case .audio(let file):
      return file
    case .document(let file):
      return file
    case .photo(let file):
      return file
    case .sticker(let file):
      return file
    case .video(let file):
      return file
    case .voice(let file):
      return file
    }
  }
  
  var getType: FileType {
    switch file {
    case .audio:
      return .audio
    case .document:
      return .document
    case .photo:
      return .photo
    case .sticker:
      return .sticker
    case .video:
      return .video
    case .voice:
      return .voice
    }
  }
  
  
  init(upload: FileLink, file: Message, time: Int) throws {
    switch file.type {
    case .audio(let file):
      self.file = .audio(file)
    case .document(let file):
      self.file = .document(file)
    case .photo(let file):
      self.file = .photo(file)
    case .sticker(let file):
      self.file = .sticker(file)
    case .video(let file):
      self.file = .video(file)
    case .voice(let file):
      self.file = .voice(file)
    default:
      throw CacheError.WrongType
    }
    
    self.uploadTime = time
    self.uploadData = upload
  }
}

public enum FileType: String {
  case audio
  case document
  case photo
  case sticker
  case video
  case voice
}

extension FileType {
  public var method: String {
    switch self {
    case .audio:
      return "sendAudio"
    case .document:
      return "sendDocument"
    case .photo:
      return "sendPhoto"
    case .sticker:
      return "sendSticker"
    case .video:
      return "sendVideo"
    case .voice:
      return "sendVoice"
    }
  }
}




