//
//  Pelican+Methods.swift
//  Pelican
//
//  Created by Takanu Kyriako on 27/03/2017.
//
//

import Dispatch     // Linux thing.
import Foundation
import Vapor
import FluentProvider
import HTTP
import FormData
import Multipart

/** Required for classes that wish to receive message objects once the upload is complete.
 */
public protocol ReceiveUpload {
  func receiveMessage(message: Message)
}


/** This extension contains all available Bot API methods.
*/
public extension Pelican {

	/*
  
  // Sends a file that has already been uploaded.
  // The caption can't be used on all types...
  public func sendFile(chatID: Int, file: SendType, replyMarkup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) -> Message? {
    var query: [String:NodeConvertible] = [
      "chat_id":chatID]
    
    // Ensure only the files that can have caption types get a caption query
    let captionTypes = ["audio", "photo", "video", "document", "voice"]
    if caption != "" && captionTypes.index(of: file.messageTypeName) != nil { query["caption"] = caption }
    
    // Check whether any other query needs to be added
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    if disableNtf != false { query["disable_notification"] = disableNtf }
		
    
    // Combine the query built above with the one the file provides
    let finalQuery = query.reduce(file.getQuery(), { r, e in var r = r; r[e.0] = e.1; return r })
    
    // Try sending it!
    guard let response = try? drop.client.post(apiURL + file.method, query: finalQuery) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    // Check if the response is valid
    if response.data["ok"]?.bool != true {
      drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
      return nil
    }
    
		// Attempt to extract the response
		let node = response.json!.makeNode(in: nil)["result"]!
		guard let message = try? Message(row: Row(node)) else {
			drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
			return nil
		}
		
    return message
  }
  
  /** I mean you're not "necessarily" uploading a file but whatever, it'll do for now */
  public func uploadFile(link: FileLink, callback: ReceiveUpload? = nil, chatID: Int, markup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) {
		
		
		// The PhotoSize/Photo model stopped working, this can't be used until later.
		/*
    // Check to see if we need to upload this in the first place.
    // If not, send the file using the link.
    let search = cache.find(upload: link, bot: self)
    if search != nil {
      print("SENDING...")
      let message = sendFile(chatID: chatID, file: search!, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyMessageID)
      if callback != nil {
        callback!.receiveMessage(message: message!)
      }
      return
    }
		*/

    // Obtain the file data cache
    let data = cache.get(upload: link)
    if data == nil { return }
		
		
    // Make the multipart/form-data
		let url = apiURL + "/" + link.type.method
    let request = Request(method: .post, uri: url)
		
		
		// Create the form data and assign some initial values
    var form: [String:FormData.Field] = [:]
    form["chat_id"] = Field(name: "chat_id", filename: nil, part: Part(headers: [:], body: String(chatID).bytes))
    form[link.type.rawValue] = Field(name: link.type.rawValue, filename: link.name, part: Part(headers: [:], body: data!))
		
    
    // Check whether any other query needs to be added as form data.
    if caption != "" {
			form["caption"] = Field(name: "caption", filename: nil, part: Part(headers: [:], body: caption.bytes))
		}
    if markup != nil {
			form["reply_markup"] = Field(name: "reply_markup", filename: nil, part: Part(headers: [:], body: try! markup!.makeRow().converted(to: JSON.self).makeBytes()))
		}
    if replyMessageID != 0 {
			form["reply_to_message_id"] = Field(name: "reply_to_message_id", filename: nil, part: Part(headers: [:], body: String(replyMessageID).bytes))
		}
    if disableNtf != false {
			form["disable_notification"] = Field(name: "disable_notification", filename: nil, part: Part(headers: [:], body: String(disableNtf).bytes))
		}
		
    // This is the "HEY, I WANT MY BODY TO BE LIKE THIS AND TO PARSE IT LIKE FORM DATA"
    request.formData = form
		
    //print(url)
    //print(request)
    print("UPLOADING...")
    
    let queueDrop = drop
    
    uploadQueue.sync {
      let response = try! queueDrop.client.respond(to: request)
      self.finishUpload(link: link, response: response, callback: callback)
		
			
		// Old experiment for building client requests, please ignore.
		/*
		uploadQueue.sync {
			
       // Get the URL in a protected way
       guard let url = URL(string: url) else {
       print("Error: cannot create URL")
       return
       }
       // Build the body data set
       let bytes = request.body.bytes
       let data = Data(bytes: bytes!.array)
       
       // Build the URL request
       var req = URLRequest(url: url)
       
       // Add the right HTTP headers
       for header in request.headers {
       req.addValue(header.value, forHTTPHeaderField: header.key.key)
       }
       
       // Configure the request and set the payload
       req.httpMethod = "POST"
       req.httpBody = data
       req.httpShouldHandleCookies = false
       
       // Set the task
       let task = URLChatSession.shared.dataTask(with: req) {
       data, handler, error in
       
       let result = try! JSON(bytes: (data?.array)!)
       print(result)
       }
       
       // Make it rain.
       task.resume()
       */
    }
    return
  }
  
  public func finishUpload(link: FileLink, response: Response, callback: ReceiveUpload? = nil) {
    
    // All you need is the correct URL with the body of the
    //        guard let response = try? drop.client.post(url, headers: request.headers, body: request.body) else {
    //            drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
    //            return nil
    //        }
    
    // Check if the response is valid
    if response.data["ok"]?.bool != true {
      drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
      return
    }
    
		// Attempt to extract the response
		let node = response.json!.makeNode(in: nil)["result"]!
		guard let message = try? Message(row: Row(node)) else {
			drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
			return
		}
		
    // If we have a callback, call it.
    if callback != nil {
      callback!.receiveMessage(message: message)
    }
    
    // Add it to the cache
    _ = cache.add(upload: link, message: message)
    return
    
  }

	*/
}

