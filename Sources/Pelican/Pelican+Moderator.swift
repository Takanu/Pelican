
import Foundation
import Vapor

/**
Manages user access to the bot through a permanent blacklist feature (that works in conjunction with FloodLimit), while
enabling the creation of custom user lists for flexible permission and other custom user and chat grouping systems.
*/
public class Moderator {
	
	/// Holds the main bot class to ensure access to Chat and User Session lists.
	var bot: Pelican?
	
	var chatLists: [String:[Int]] = [:]
	var userLists: [String:[Int]] = [:]
	
	var chatBlacklist: [Int] = []
	var userBlacklist: [Int] = []
	
	var chatListSwitch: [String:Bool] = [:]
	var userListSwitch: [String:Bool] = [:]
	
	var getChatCategories: [String] { return chatLists.keys.array }
	var getUserCategories: [String] { return userLists.keys.array }
	var getChatLists: [String:[Int]] { return chatLists }
	var getUserLists: [String:[Int]] { return userLists }
  
	public init() { }
	
	/**
	Attempts to add a user to an existing list.
	- returns: True if successful, false if the list does not exist.
	*/
	public func addUsers(toList name: String, users: UserSession...) -> Bool {
		
		// If it doesn't exist, return false
		if userLists[name] == nil { return false }
		
		// Otherwise add the user to the list and ensure their user session is amended.
		for user in users {
			
			let id = user.info.tgID
			
			if userLists[name]!.contains(id) == false {
				userLists[name]!.append(user.info.tgID)
				user.permissions.append(name)
			}
		}
		
		return true
	}
	
	/**
	Attempts to remove a user from an existing list.
	- returns: True if successful, false if the list does not exist.
	*/
	public func removeUsers(fromList name: String, users: UserSession...) -> Bool {
		
		// If it doesn't exist, return false
		if userLists[name] == nil { return false }
		
		// Otherwise add the user to the list and ensure their user session is amended.
		for user in users {
			
			let id = user.info.tgID
			
			if let listIndex = userLists[name]!.index(of: id) {
				userLists[name]!.remove(at: listIndex)
				
				// Remove it from the session permissions list if it was on it.
				if let permIndex = user.permissions.index(of: name) {
					user.permissions.remove(at: permIndex)
				}
			}
		}
		
		return true
	}
	
	/**
	Attempts to add chat IDs to a given list.
	- returns: True if successful, false if the list does not exist.
	*/
	public func addChats(toList name: String, chatIDs: Int...) -> Bool {
		
		if chatLists[name] == nil { return false }
		
		for id in chatIDs {
			
			if chatLists[name]!.contains(id) == false {
				chatLists[name]!.append(id)
			}
			
			// If the chat exists as a session, modify it's permissions
			if bot!.getChatSessions[id] != nil {
				
				if bot!.getChatSessions[id]!.permissions.contains(name) == false {
					bot!.getChatSessions[id]!.permissions.append(name)
				}
			}
		}
		
		return true
	}
	
	/**
	Attempts to remove chat IDs to a given Moderator list.
	- returns: True if successful or if it was already removed, false if the list does not exist.
	If removed, any chats that currently have an active session will also
	*/
	public func removeChats(fromList name: String, chatIDs: Int...) -> Bool {
		
		if chatLists[name] == nil { return false }
		
		for id in chatIDs {
			
			// If the ID is in the list, remove it
			if let listIndex = chatLists[name]!.index(of: id) {
				chatLists[name]!.remove(at: listIndex)
			
				// If the chat exists as a session, modify it's permissions
				if bot!.getChatSessions[id] != nil {
					
					let session = bot!.getChatSessions[id]!
					
					if let permIndex = session.permissions.index(of: name) {
						bot!.getChatSessions[id]!.permissions.remove(at: permIndex)
					}
				}
			}
		}
		
		return true
	}
	
	/**
	Creates a new user list category.
	*/
	public func addUserList(name: String) {
		
		if userLists[name] != nil { return }
			
		else {
			userLists[name] = []
		}
	}
	
	/**
	Deletes a user list category, and all the entries in it.  Please note that the blacklist cannot be removed.
	*/
	public func removeUserList(name: String) {
		
		if userLists[name] == nil { return }
		
		// Remove the permission tag from any users that currently have it.
		for id in userLists[name]! {
			
			// If the chat exists as a session, modify it's permissions
			if bot!.getUserSessions[id] != nil {
				
				let session = bot! .getUserSessions[id]!
				
				if let permIndex = session.permissions.index(of: name) {
					bot!.getUserSessions[id]!.permissions.remove(at: permIndex)
				}
			}
		}
		
		userLists.removeValue(forKey: name)
	}
	
	/**
	Adds a new chat list category
	*/
	public func addChatList(name: String) {
		
		if chatLists[name] != nil { return }
		
		else {
			chatLists[name] = []
		}
	}
	
	/** 
	Removes a chat list category, and all the entries in it if it has any.
	Please note that the blacklist cannot be removed.
	*/
	public func removeChatList(name: String) {
		
		if chatLists[name] == nil { return }
		
		// Remove the permission tag from any users that currently have it.
		for id in chatLists[name]! {
			
			// If the chat exists as a session, modify it's permissions
			if bot!.getChatSessions[id] != nil {
				
				let session = bot!.getChatSessions[id]!
				
				if let permIndex = session.permissions.index(of: name) {
					bot!.getChatSessions[id]!.permissions.remove(at: permIndex)
				}
			}
		}
		
		chatLists.removeValue(forKey: name)
	}
	
	
	// BLACKLIST
	
	/**
	Adds the given users to the blacklist, and terminates any sessions they currently have with the bot.
	Adding a user to the blacklist will also prevent their updates from being received by the bot to any chat sessions.
	*/
	public func addToBlacklist(userIDs: Int...) {
		
		// Add the users to the blacklist if they aren't already there
		for id in userIDs {
			
			if userBlacklist.contains(id) == false {
				userBlacklist.append(id)
			}
			
			// Ask Pelican to remove the session, as it can perform any necessary clean-up operations.
			bot!.removeUserSession(userID: id)
		}
	}
	
	
	/**
	Adds the given chats to the blacklist, and terminates any sessions they currently have with the bot.
	Adding a chat to the blacklist will also prevent that chat from initiating any new sessions.
	*/
	public func addToBlacklist(chatIDs: Int...) {
		
		// Add the chats to the blacklist if they aren't already there
		for id in chatIDs {
			
			if chatBlacklist.contains(id) == false {
				chatBlacklist.append(id)
			}
			
			// Ask Pelican to remove the session, as it can perform any necessary clean-up operations.
			bot!.removeChatSession(chatID: id)
		}
	}
	
	/**
	Removes the given users from the blacklist, allowing updates they make to be received by the bot.
	*/
	public func removeFromBlacklist(userIDs: Int...) {
		
		// Remove the users from the blacklist if they ended up there
		for id in userIDs {
			
			if let index = userBlacklist.index(of: id) {
					userBlacklist.remove(at: index)
			}
		}
	}
	
	/**
	Removes the given chat from the blacklist, allowing updates they make to be received by the bot.
	*/
	public func removeFromBlacklist(chatIDs: Int...) {
		
		// Remove the chats from the blacklist if they ended up there
		for id in chatIDs {
			
			if let index = chatBlacklist.index(of: id) {
				chatBlacklist.remove(at: index)
			}
		}
	}
	
	/**
	Checks to see if the given user ID is in the blacklist.
	- returns: True if they are in the blacklist, false if not.
	*/
	public func checkBlacklist(userID: Int) -> Bool	{
		
		if userBlacklist.contains(userID) == true {
			return true
		}
		
		return false
	}
	
	/**
	Checks to see if the given chat ID is in the blacklist.
	- returns: True if they are in the blacklist, false if not.
	*/
	public func checkBlacklist(chatID: Int) -> Bool	{
		
		if chatBlacklist.contains(chatID) == true {
			return true
		}
		
		return false
	}
}
