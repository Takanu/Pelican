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
import HTTP
import FormData
import Multipart


/** This extension contains all available Bot API methods.
*/
public extension Pelican {
  
  
  // A simple function used to test the authentication key
  public func getMe() -> User? {
    // Attempt to get a response
    guard let response = try? drop.client.post(apiURL + "/getMe") else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    // Check if the response is valid
    if response.data["ok"]?.bool != true {
      drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
      return nil
    }
    
    // Attempt to extract the response
    let node = response.json!.node["result"]?.node
    guard let user = try? User(node: node, in: TGContext.response) else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return nil
    }
    
    // Return the object
    return user
  }
  
  

  // Will let you manually fetch updates.
  public func getUpdates(incrementUpdate: Bool = true) -> [Polymorphic]? {
    // Call the bot API for any new messages
    let query = makeUpdateQuery()
    guard let response = try? drop.client.post(apiURL + "/getUpdates", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    // Get the results of the update request
    guard let result: Array = response.data["result"]?.array else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return nil
    }
    return result
  }
  
  
  
  // Sends a message.  Must contain a chat ID, message text and an optional MarkupType.
  public func sendMessage(chatID: Int, text: String, replyMarkup: MarkupType?, parseMode: String = "", disableWebPreview: Bool = false, disableNtf: Bool = false, replyMessageID: Int = 0) -> Message? {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "text": text,
      "disable_web_page_preview": disableWebPreview,
      "disable_notification": disableNtf
    ]
    
    // Check whether any other query needs to be added
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if parseMode != "" { query["parse_mode"] = parseMode }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    
    // Try sending it!
    guard let response = try? drop.client.post(apiURL + "/sendMessage", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    //print(response)
    
    // Check if the response is valid
    if response.data["ok"]?.bool != true {
      drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
      return nil
    }
    
    // Attempt to extract the response
    let node = response.json!.node["result"]?.node
    guard let message = try? Message(node: node, in: TGContext.response) else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return nil
    }
    
    return message
  }
  
  
  // Forwards a message of any kind.  On success, the sent Message is returned.
  public func forwardMessage(toChatID: Int, fromChatID: Int, fromMessageID: Int, disableNtf: Bool = false) -> Message? {
    let query: [String:CustomStringConvertible] = [
      "chat_id":toChatID,
      "from_chat_id": fromChatID,
      "message_id": fromMessageID,
      "disable_notification": disableNtf
    ]
    
    // Try sending it!
    guard let response = try? drop.client.post(apiURL + "/forwardMessage", query: query) else {
      drop.console.error(TGReqError.NoResponse.rawValue, newLine: true)
      return nil
    }
    
    // Check if the response is valid
    if response.data["ok"]?.bool != true {
      drop.console.error(TGReqError.BadResponse.rawValue, newLine: true)
      return nil
    }
    
    // Attempt to extract the response
    let node = response.json!.node["result"]?.node
    guard let message = try? Message(node: node, in: TGContext.response) else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return nil
    }
    
    return message
  }
  
  
  // Sends a file that has already been uploaded.
  // The caption can't be used on all types...
  public func sendFile(chatID: Int, file: SendType, replyMarkup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) -> Message? {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID]
    
    // Ensure only the files that can have caption types get a caption query
    //let captionTypes = ["audio", "photo", "video", "document", "voice"]
    //if caption != "" && captionTypes.index(of: file.messageTypeName) != nil { query["caption"] = caption }
    
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
    let node = response.json!.node["result"]?.node
    guard let message = try? Message(node: node, in: TGContext.response) else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return nil
    }
    
    return message
  }
  
  /** I mean you're not "necessarily" uploading a file but whatever, it'll do for now */
  public func uploadFile(link: FileUpload, chatID: Int, markup: MarkupType?, caption: String = "", disableNtf: Bool = false, replyMessageID: Int = 0) {
    
    // Check to see if we need to upload this in the first place.
    // If not, send the file using the link.
    let search = cache.find(upload: link, bot: self)
    if search != nil {
      print("SENDING...")
      _ = sendFile(chatID: chatID, file: search!, replyMarkup: markup, caption: caption, disableNtf: disableNtf, replyMessageID: replyMessageID)
      return
    }
    
    // Obtain t
    let data = cache.get(upload: link)
    if data == nil { return }
    
    // Make the multipart/form-data
    let request = Response()
    var form: [String:Field] = [:]
    form["chat_id"] = Field(name: "chat_id", filename: nil, part: Part(headers: [:], body: String(chatID).bytes))
    form[link.type.rawValue] = Field(name: link.type.rawValue, filename: "NOODLE", part: Part(headers: [:], body: data!))
    // A filename is required here
    
    
    // Check whether any other query needs to be added
    if markup != nil { form["reply_markup"] = Field(name: "reply_markup", filename: nil, part: Part(headers: [:], body: try! markup!.makeJSON().makeBytes())) }
    if replyMessageID != 0 { form["reply_to_message_id"] = Field(name: "reply_to_message_id", filename: nil, part: Part(headers: [:], body: String(replyMessageID).bytes)) }
    if disableNtf != false { form["disable_notification"] = Field(name: "disable_notification", filename: nil, part: Part(headers: [:], body: String(disableNtf).bytes)) }
    
    
    // This is the "HEY, I WANT MY BODY TO BE LIKE THIS AND TO PARSE IT LIKE FORM DATA"
    request.formData = form
    let url = apiURL + "/" + link.type.method
    //print(url)
    //print(request)
    print("UPLOADING...")
    
    let queueDrop = drop
    
    uploadQueue.sync {
      let response = try! queueDrop.client.post(url, headers: request.headers, body: request.body)
      self.finishUpload(link: link, response: response)
      
      /*
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
       let task = URLSession.shared.dataTask(with: req) {
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
  
  public func finishUpload(link: FileUpload, response: Response) {
    
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
    let node = response.json!.node["result"]?.node
    guard let message = try? Message(node: node, in: TGContext.response) else {
      drop.console.error(TGReqError.ResponseNotExtracted.rawValue, newLine: true)
      return
    }
    
    // Add it to the cache
    _ = cache.add(upload: link, message: message)
    return
    
  }
  
  
  //////////////////////////////////////////////////////////////////////////////////
  //// TELEGRAM CHAT MANAGEMENT METHOD IMPLEMENTATIONS
  
  
  /* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
  public func sendChatAction(chatID: Int, action: ChatAction) {
    let query: [String:CustomStringConvertible] = [
      "chat_id": chatID,
      "action": action.rawValue
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/sendChatAction", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object. */
  public func getUserProfilePhotos(userID: Int, offset: Int = 0, limit: Int = 100) {
    
    // I know this could be neater, figure something else later
    var adjustedLimit = limit
    if limit > 100 { adjustedLimit = 100 }
    
    let query: [String:CustomStringConvertible] = [
      "user_id": userID,
      "offset": offset,
      "limit": adjustedLimit
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getUserProfilePhotos", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again. */
  public func getFile(fileID: Int) {
    let query: [String:CustomStringConvertible] = [
      "file_id": fileID
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getFile", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to kick a user from a group or a supergroup. In the case of supergroups, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the group for this to work. Returns True on success. */
  public func kickChatMember(chatID: Int, userID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id": chatID,
      "user_id": userID
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatMember", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  
  /* Use this method for your bot to leave a group, supergroup or channel. Returns True on success. */
  public func leaveChat(chatID: Int, userID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "user_id": userID
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatMember", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  
  
  /* Use this method to unban a previously kicked user in a supergroup. The user will not return to the group automatically, but will be able to join via link, etc. The bot must be an administrator in the group for this to work. Returns True on success. */
  public func unbanChatMember(chatID: Int, userID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "user_id": userID
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatMember", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a Chat object on success. */
  public func getChat(chatID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChat", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  // Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember.
  // Doesn't include other bots - if the chat is a group of supergroup and no admins were appointed, only the
  // creator will be returned.
  public func getChatAdministrators(chatID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatAdministrators", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  // Get the number of members in a chat. Returns Int on success.
  public func getChatMemberCount(chatID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatMembersCount", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  // Get information about a member of a chat. Returns a ChatMember object on success
  public func getChatMember(chatID: Int, userID: Int) {
    let query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "user_id": userID
    ]
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getChatMember", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  //////////////////////////////////////////////////////////////////////////////////
  //// TELEGRAM EDIT MESSAGE METHOD IMPLEMENTATIONS
  
  public func editMessageText(chatID: Int, messageID: Int = 0, text: String, replyMarkup: MarkupType?, parseMode: String = "", disableWebPreview: Bool = false, replyMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "text": text,
      "disable_web_page_preview": disableWebPreview,
      ]
    
    // Check whether any other query needs to be added
    if messageID != 0 { query["message_id"] = messageID }
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if parseMode != "" { query["parse_mode"] = parseMode }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/editMessageText", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  public func editMessageCaption(chatID: Int, messageID: Int = 0, text: String, replyMarkup: MarkupType?, replyMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "text": text,
      ]
    
    // Check whether any other query needs to be added
    if messageID != 0 { query["message_id"] = messageID }
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    
    // Try sending it!
    do {
      let _ = try drop.client.post(apiURL + "/editMessageCaption", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  public func editMessageReplyMarkup(chatID: Int, messageID: Int = 0, replyMarkup: MarkupType?, replyMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      ]
    
    // Check whether any other query needs to be added
    if messageID != 0 { query["message_id"] = messageID }
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/editMessageReplyMarkup", query: query)
    }
    catch {
      print(error)
    }
  }
  
  
  //////////////////////////////////////////////////////////////////////////////////
  //// TELEGRAM CALLBACK METHOD IMPLEMENTATIONS
  
  
  // Send answers to callback queries sent from inline keyboards.
  // The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
  public func answerCallbackQuery(queryID: String, text: String = "", showAlert: Bool = false, url: String = "", cacheTime: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "callback_query_id":queryID,
      "show_alert": showAlert,
      "cache_time": cacheTime
    ]
    
    // Check whether any other query needs to be added
    if text != "" { query["text"] = text }
    if url != "" { query["url"] = url }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/answerCallbackQuery", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  // Use this method to send answers to an inline query. On success, True is returned.
  // No more than 50 results per query are allowed.
  public func answerInlineQuery(inlineQueryID: String, results: [InlineResult], cacheTime: Int = 300, isPersonal: Bool = false, nextOffset: Int = 0, switchPM: String = "", switchPMParam: String = "") {
    var query: [String:CustomStringConvertible] = [
      "inline_query_id": inlineQueryID
    ]
    
    var resultQuery: [JSON] = []
    for result in results {
      let json = try! result.makeJSON()
      resultQuery.append(json)
    }
    
    query["results"] = try! resultQuery.makeJSON().serialize().toString()
    
    // Check whether any other query needs to be added
    if cacheTime != 300 { query["cache_time"] = cacheTime }
    if isPersonal != false { query["is_personal"] = isPersonal }
    if nextOffset != 0 { query["next_offset"] = nextOffset }
    if switchPM != "" { query["switch_pm_text"] = switchPM }
    if switchPMParam != "" { query["switch_pm_parameter"] = switchPMParam }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/answerInlineQuery", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  
  
  //////////////////////////////////////////////////////////////////////////////////
  //// TELEGRAM GAME METHOD IMPLEMENTATIONS
  
  
  /* Use this method to send a game. On success, the sent Message is returned. */
  public func sendGame(chatID: Int, gameName: String, replyMarkup: MarkupType?, disableNtf: Bool = false, replyMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "chat_id":chatID,
      "game_short_name": gameName
    ]
    
    // Check whether any other query needs to be added
    if replyMarkup != nil { query["reply_markup"] = replyMarkup!.getQuery() }
    if replyMessageID != 0 { query["reply_to_message_id"] = replyMessageID }
    if disableNtf != false { query["disable_notification"] = disableNtf }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/sendGame", query: query)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited Message, otherwise returns True. Returns an error, if the new score is not greater than the user's current score in the chat and force is False. */
  public func setGameScore(userID: Int, score: Int, force: Bool = false, disableEdit: Bool = false, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "user_id":userID,
      "score": score
    ]
    
    // Check whether any other query needs to be added
    if force != false { query["force"] = force }
    if disableEdit != false { query["disable_edit_message"] = disableEdit }
    
    // THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
    if inlineMessageID == 0 {
      query["chat_id"] = chatID
      query["message_id"] = messageID
    }
      
    else {
      query["inline_message_id"] = inlineMessageID
    }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/setGameScore", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
  
  /* Use this method to get data for high score tables. Will return the score of the specified user and several of his neighbors in a game. On success, returns an Array of GameHighScore objects.
   
   This method will currently return scores for the target user, plus two of his closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change. */
  public func getGameHighScores(userID: Int, chatID: Int = 0, messageID: Int = 0, inlineMessageID: Int = 0) {
    var query: [String:CustomStringConvertible] = [
      "user_id":userID
    ]
    
    // THIS NEEDS EDITING PROBABLY, NOT NICE DESIGN
    if inlineMessageID == 0 {
      query["chat_id"] = chatID
      query["message_id"] = messageID
    }
      
    else {
      query["inline_message_id"] = inlineMessageID
    }
    
    // Try sending it!
    do {
      _ = try drop.client.post(apiURL + "/getGameHighScores", query: query)
      //print(result)
    }
    catch {
      print(error)
    }
  }
}

