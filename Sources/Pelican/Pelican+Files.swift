
import Foundation
import Vapor

// Errors related to update processing.  Might merge the two?
private enum CacheError: String, Error {
  case BadBundle = "The cache path for Telegram could not be found.  Please ensure Public/ is a folder in your project directory."
  case WrongType = "The file could not be added because it has the wrong type."
  case LocalNotFound = "The local resource you attempted to upload could not be found or processed."
}

/// Manages a database of currently active file links for re-use, as well as asynchronously uploads content
/// that doesn't have a link.
public class CacheManager {
  private var bundle: Bundle?
  
  // Caches
  var audios: [CacheFile] = []
  var photos: [CacheFile] = []
  var documents: [CacheFile] = []
  var stickers: [CacheFile] = []
  var videos: [CacheFile] = []
  var voices: [CacheFile] = []
  
  var cacheLength: Int = 0        // The length of time a file is cached on Telegram's servers before
  // it needs re-uploading. 0 = No timer.
  
  init() { }
  
  func setBundlePath(_ path: String) throws {
    self.bundle = Bundle(path: path)
    if self.bundle == nil { throw CacheError.BadBundle }
  }
  
  
  // Used to keep cache types separate, to make cache searching less intensive?  (idk)
  // This should be replaced with one stack that can then filter using generics.
  internal func getCache(type: FileType) -> [CacheFile] {
    switch type {
    case .audio:
      return audios
    case .photo:
      return photos
    case .document:
      return documents
    case .sticker:
      return stickers
    case .video:
      return videos
    case .voice:
      return voices
    }
  }
  
  internal func setCache(_ cache: [CacheFile], type: FileType) {
    switch type {
    case .audio:
      audios = cache; return
    case .photo:
      photos = cache; return
    case .document:
      documents = cache; return
    case .sticker:
      stickers = cache; return
    case .video:
      videos = cache; return
    case .voice:
      voices = cache; return
    }
  }
  
  /** Adds the cached resource to the list given a successful response message. */
  func add(upload: FileUpload, message: Message) -> Bool {
    let file = try! CacheFile(upload: upload, file: message, time: 0)
    var cache: [CacheFile] = getCache(type: file.getType)
    
    if cache.contains(where: { $0.uploadData.id == upload.id }) == false {
      cache.append(file)
      setCache(cache, type: file.getType)
      return true
    }
    
    return false
  }
  
  /** Tries to find whether an uploaded version of that file exists in the cache.
   Returns the object if true, or nothing if false. */
  func find(upload: FileUpload, bot: Pelican) -> SendType? {
    let cache = getCache(type: upload.type)
    for item in cache {
      
      // If the item hashes dont match, keep cycling
      if item.uploadData.id != upload.id { continue }
      
      // If they do and the upload timer has expired, return no ID and remove it from the cache
      if bot.globalTimer > item.uploadTime + cacheLength && cacheLength != 0 { return nil }
      
      // Otherwise, return the ID
      return item.getFile
    }
    return nil
  }
  
  /** Attempts to retrieve the raw data for the requested resource. */
  func get(upload: FileUpload) -> Bytes? {
    
    switch upload.location {
    case .name(path: let path, name: let name, ext: let ext):
      if bundle == nil {
        print(CacheError.BadBundle.rawValue)
        return nil
      }
      
      guard let url = bundle!.url(forResource: name, withExtension: ext, subdirectory: path)
        else {
          print(CacheError.LocalNotFound.rawValue)
          return nil
      }
      
      do {
        let image = try Data(contentsOf: url)
        let bytes = try image.makeBytes()
        return bytes
        
      } catch {
        print(CacheError.LocalNotFound.rawValue)
        return nil
      }
      
    default:
      return nil
    }
  }
}

// Represents a file that has been uploaded and is stored in the cache for
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
  var uploadTime: Int             // The time at which it was uploaded.
  var uploadData: FileUpload      // The file upload type that was used to upload it.
  
  var getFile: SendType {
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
  
  
  init(upload: FileUpload, file: Message, time: Int) throws {
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


/** Defines a file to be uploaded using the sendFile TelegramBot function. */
public struct FileUpload {
  public enum UploadLocation {
    case name((path: String, name: String, ext: String))
    //        case path(String)
    case http(String)
  }
  
  public var location: UploadLocation
  public var type: FileType
  public var id: String {
    switch location {
    case .name(path: let path, name: let name, ext: let ext):
      return path + name + ext
      //        case .path(let path):
    //            return path
    case .http(let http):
      return http
    }
  }
  
  public init(withPath path: String, name: String, ext: String, type: FileType) {
    self.location = .name((path, name, ext))
    self.type = type
  }
  
  //    init(withPath path: String, type: TGFileType) {
  //        self.location = .path(path)
  //        self.type = type
  //    }
  
  public init(withHTTP http: String, type: FileType) {
    self.location = .http(http)
    self.type = type
  }
}


