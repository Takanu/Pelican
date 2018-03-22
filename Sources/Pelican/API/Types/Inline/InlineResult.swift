
import Foundation



/**
Used for a result/your response of an inline query.
 */
public protocol InlineResult: Codable {
	
	/// Defines the metatype, purely used for encoding and decoding.
	var metatype: InlineResultType { get }
	
	/// Defines the type of the result being given.
	var type: String { get }
}

