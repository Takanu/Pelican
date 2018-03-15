
import Foundation

/**
Represents a file that has been uploaded and is stored in the cache for.
Used for obtaining and re-using the resource, as well as
*/
struct CacheFile: Equatable {
	
	/// The message file being stored
	var file: MessageFile
	
	/// The time it was last uploaded (useful for predicting when it needs to be uploaded again).
	var uploadTime: Date
	
	/**
	Attempts to create the type for the given file.  Warning: This will fail if the file has no file ID, thus
	indicating it has never been uploaded to Telegram.  A file must already be uploaded to be cached.
	*/
	init?(file: MessageFile) {
		
		if file.fileID == nil { return nil }
		
		self.file = file
		self.uploadTime = Date()
	}
	
	public static func ==(lhs: CacheFile, rhs: CacheFile) -> Bool {
		
		if lhs.uploadTime != rhs.uploadTime { return false }
		if lhs.file.fileID != rhs.file.fileID { return false }
		if lhs.file.url != rhs.file.url { return false }
		
		return true
	}
	
}

