//
//  Pelican+Moderator.swift
//  kabuki
//
//  Created by Takanu Kyriako on 25/03/2017.
//
//

import Foundation
import Vapor

public class Moderator {
  var userBlacklist: [User] = []
  var userWhitelist: [User] = []
  
  var chatBlacklist: [Chat] = [] // Used to block a chat if no user data is available.
  var chatWhitelist: [Chat] = [] // Used for testing or small betas, where you'd only like the beta to occur for a specific chat or chats.
  
  var blacklistEnabled: Bool = false
  var whitelistEnabled: Bool = false
  
  
  public init() { }
  
  // AUTHORISATION CHECK FUNCTIONS
  public func authorise(user: User) -> Bool {
    if blacklistEnabled == true {
      if checkBlacklist(user: user) == true { return false }
    }
    
    if whitelistEnabled == true {
      if checkBlacklist(user: user) == true { return true }
      else { return false }
    }
    
    return true
  }
  
  public func authorise(chat: Chat) -> Bool {
    if blacklistEnabled == true {
      if checkBlacklist(chat: chat) == true { return false }
    }
    
    if whitelistEnabled == true {
      if checkBlacklist(chat: chat) == true { return true }
      else { return false }
    }
    
    return true
  }
  
  public func authorise(userID: Int) -> Bool {
    if blacklistEnabled == true {
      if userBlacklist.contains(where: {$0.tgID == userID} ) == true { return false }
    }
    
    if whitelistEnabled == true {
      if userWhitelist.contains(where: {$0.tgID == userID} ) == true { return true }
      else { return false }
    }
    
    return true
  }
  
  public func authorise(chatID: Int) -> Bool {
    if blacklistEnabled == true {
      if chatBlacklist.contains(where: {$0.tgID == chatID} ) == true { return false }
    }
    
    if whitelistEnabled == true {
      if chatWhitelist.contains(where: {$0.tgID == chatID} ) == true { return true }
      else { return false }
    }
    
    return true
  }

  
  
  // RAW LIST CHECK FUNCTIONS
  public func checkBlacklist(user: User) -> Bool {
    if userBlacklist.count > 0 {
      if userBlacklist.contains(where: { $0.tgID == user.tgID } ) == true {
        return true
      }
    }
    return false
  }
  
  public func checkBlacklist(chat: Chat) -> Bool {
    if chatBlacklist.count > 0 {
      if chatBlacklist.contains(where: { $0.tgID == chat.tgID } ) == true {
        return true
      }
    }
    return false
  }
  
  public func checkWhitelist(user: User) -> Bool {
    if userWhitelist.count > 0 {
      if userWhitelist.contains(where: { $0.tgID == user.tgID } ) == true {
        return true
      }
    }
    return false
  }
  
  public func checkWhitelist(chat: Chat) -> Bool {
    if chatWhitelist.count > 0 {
      if chatWhitelist.contains(where: { $0.tgID == chat.tgID } ) == true {
        return true
      }
    }
    return false
  }
  
  
  // ADD TO LISTS!
  public func addToBlacklist(user: User) {
    if checkWhitelist(user: user) == true {
      // remove from the whitelist if in the blacklist
    }
    userBlacklist.append(user)
  }
  
  public func addToBlacklist(chat: Chat) {
    if checkWhitelist(chat: chat) == true {
      // remove from the whitelist if in the blacklist
    }
    chatBlacklist.append(chat)
  }
  
  public func addToWhitelist(user: User) {
    if checkBlacklist(user: user) == true {
      // remove from the blacklist if in the whitelist
    }
    userWhitelist.append(user)
  }

  public func addToWhitelist(chat: Chat) {
    if checkBlacklist(chat: chat) == true {
      // remove from the blacklist if in the whitelist
    }
    chatWhitelist.append(chat)
  }
  
  public func removeFromBlacklist(user: User) {
    for (i, value) in userBlacklist.enumerated() {
      if value.tgID == user.tgID {
        userBlacklist.remove(at: i)
        break
      }
    }
  }
  
  public func removeFromBlacklist(chat: Chat) {
    if checkBlacklist(chat: chat) == true {
      for (i, value) in chatBlacklist.enumerated() {
        if value.tgID == chat.tgID {
          chatBlacklist.remove(at: i)
          break
        }
      }
    }
  }
  
  public func removeFromWhitelist(user: User) {
    for (i, value) in userWhitelist.enumerated() {
      if value.tgID == user.tgID {
        userWhitelist.remove(at: i)
        break
      }
    }
  }
  
  public func removeFromWhitelist(chat: Chat) {
    for (i, value) in chatWhitelist.enumerated() {
      if value.tgID == chat.tgID {
        chatWhitelist.remove(at: i)
        break
      }
    }
  }
  
  
  public func removeFromAll(user: User) {
    removeFromWhitelist(user: user)
    removeFromBlacklist(user: user)
  }
  
  public func removeFromAll(chat: Chat) {
    removeFromWhitelist(chat: chat)
    removeFromBlacklist(chat: chat)
  }
  
  
  public func enableBlacklist(_ enable: Bool) {
    blacklistEnabled = enable
  }
  
  public func enableWhitelist(_ enable: Bool) {
    whitelistEnabled = enable
  }
  
}
