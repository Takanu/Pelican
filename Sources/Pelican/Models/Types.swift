
import Foundation
import Vapor

// For every model that replicates the Telegram API and is designed to build queries and be converted from responses.
protocol TelegramType: Model {
}


// All types that conform to this protocol are able to convert itself into a aet of query information
protocol TelegramQuery: NodeConvertible, JSONConvertible {
    func makeQuerySet() -> [String:CustomStringConvertible]
}

// Defines classes and structs that can pass specific queries or data to a send function.
public protocol SendType {
    var method: String { get } // The method used when the API call is made
    func getQuery() -> [String:CustomStringConvertible] // Whats used to extract the required information
}


// Extensions to manipulate node entries more seamlessly
extension Node {
    mutating func addNodeEntry(name: String, value: NodeConvertible) throws {
        var object = self.nodeObject
        if object != nil {
            object![name] = try value.makeNode()
            self = try object!.makeNode()
        }
    }
    
    mutating func removeNodeEntry(name: String) throws -> Bool {
        var object = self.nodeObject
        if object != nil {
            _ = object!.removeValue(forKey: name)
            self = try object!.makeNode()
            return true
        }
            
        else { return false }
    }
    
    mutating func renameNodeEntry(from: String, to: String) throws -> Bool {
        var object = self.nodeObject
        if object != nil {
            let value = object!.removeValue(forKey: from)
            object![to] = value
            self = try object!.makeNode()
            return true
        }
            
        else { return false }
    }
    
    mutating func removeNilValues() throws {
        var object = self.nodeObject
        if object != nil {
            for value in object! {
                
                if value.value.isNull == true {
                    object!.removeValue(forKey: value.key)
                }
            }
            
            self = try object!.makeNode()
        }
    }
}

