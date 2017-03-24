//
//  CustomTypes.swift
//  beach_arcade
//
//  Created by Takanu Kyriako on 18/02/2017.
//
//  All the extra types I created for convenience.

import Foundation
import Vapor

// Defines what the thumbnail is being used for.
enum InlineThumbnailType: String {
    case contact
    case document
    case photo
    case GIF        // JPEG or GIF.
    case mpeg4GIF   // JPEG or GIF.
    case video      // JPEG only.
    case location
}

// A thumbnail to represent a preview of an inline file.  NOT FOR NORMAL FILE USE.
struct InlineThumbnail {
    //var type: ThumbnailType
    var url: String = ""
    var width: Int = 0
    var height: Int = 0
    
    init () {
        
    }
    
    func getQuerySet() -> [String : CustomStringConvertible] {
        var keys: [String:CustomStringConvertible] = [
            "thumb_url": url]
        
        if width != 0 { keys["thumb_width"] = width }
        if height != 0 { keys["thumb_height"] = height }
        return keys
    }
    
    // NodeRepresentable conforming methods
    init(node: Node, in context: Context) throws {
        //type = try node.extract("type")
        url = try node.extract("thumb_url")
        width = try node.extract("thumb_width")
        height = try node.extract("thumb_height")
    }
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [
            "url": url
        ]
        
        if width != 0 { keys["width"] = width }
        if height != 0 { keys["height"] = height }
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}


enum InputFileType {
    case fileID(String)
    case url(String)
}

// A type for handling files for sending.
class InputFile: NodeConvertible, JSONConvertible {
    var type: InputFileType
    
    // NodeRepresentable conforming methods
    required init(node: Node, in context: Context) throws {
        let fileID: String = try node.extract("file_id")
        
        if fileID != "" {
            type = .fileID(fileID)
        }
        else {
            type = .url(try node.extract("url"))
        }
    }
    
    func makeNode() throws -> Node {
        var keys: [String:NodeRepresentable] = [:]
        
        switch type{
        case .fileID(let fileID):
            keys["file_id"] = fileID
        case .url(let url):
            keys["url"] = url
        }
        
        return try Node(node: keys)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try self.makeNode()
    }
}
