
import Foundation
import Vapor
import FluentProvider

/**
For any model that replicates the Telegram API, it must inherit fron this to be designed to build queries and be converted from responses
in a way that Telegram understands.
*/
protocol TelegramType: Model {
}


// All types that conform to this protocol are able to convert itself into a aet of query information
protocol TelegramQuery: NodeConvertible, JSONConvertible {
  func makeQuerySet() -> [String:NodeConvertible]
}

// Defines classes and structs that can pass specific queries or data to a send function.
public protocol SendType {
	var messageTypeName: String { get }
  var method: String { get } // The method used when the API call is made
  func getQuery() -> [String:NodeConvertible] // Whats used to extract the required information
}

/**
Defines a type that encapsulates a request from a user, through Telegram.
*/
public protocol UpdateModel: UserUpdateModel, ChatUpdateModel {
	
}

public protocol UserUpdateModel {
	
}

public protocol ChatUpdateModel {
	
}


extension Row {
	
	/** 
	Strips row data of any entries that have a value of "null", including any nested data.
	Useful for constructing queries and requests where null values are not compatible.
	*/
	mutating func removeNullEntries() throws {

		if self.object != nil {
			for row in self.object! {
				
				if row.value.isNull == true {
					self.removeKey(row.key)
				}
				
				else if row.value.object != nil {
					var newRow = row.value
					try newRow.removeNullEntries()
					self.removeKey(row.key)
					try self.set(row.key, newRow)
				}
			}
		}
	}
}
