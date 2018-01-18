
import Foundation
import Vapor
import FluentProvider
import JSON

/** 
 Represents a Telegram "Markup Type", that defines additional special actions and interfaces
 alongside a message, such as creating a custom keyboard or forcing a userto reply to the sent 
 message.
 */
public protocol MarkupType: Codable {
  
}
