
import Foundation
import Vapor
import FluentProvider

// For every model that replicates the Telegram API and is designed to build queries and be converted from responses.
protocol TelegramType: Model {
}


// All types that conform to this protocol are able to convert itself into a aet of query information
protocol TelegramQuery: NodeConvertible, JSONConvertible {
  func makeQuerySet() -> [String:NodeConvertible]
}

// Defines classes and structs that can pass specific queries or data to a send function.
public protocol SendType {
  var method: String { get } // The method used when the API call is made
  func getQuery() -> [String:NodeConvertible] // Whats used to extract the required information
}


