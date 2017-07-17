
import Foundation
import Vapor


/**
Contains the permissions associated with a single user or chat.
*/
public class Permissions {
	
	enum IDType {
		case chat
		case user
	}
	
	private var type: IDType
	private var id: Int = 0
	private var list: [String] = []
	
	public var getID: Int { return id }
	public var getList: [String] { return list }
	
	fileprivate init(chatID: Int) {
		self.type = .chat
		self.id = chatID
	}
	
	fileprivate init(userID: Int) {
		self.type = .user
		self.id = userID
	}
	
	func add(_ permission: String) {
		
		if list.contains(permission) == true { return }
		list.append(permission)
	}
	
	func remove(_ permission: String) {
		
		if let index = list.index(of: permission) {
			list.remove(at: index)
		}
	}
	
}

/**
Manages user access to the bot through a permanent blacklist feature (that works in conjunction with FloodLimit), while
enabling the creation of custom user lists for flexible permission and other custom user and chat grouping systems.
*/
public class Moderator {
	
	/// Holds the main bot class to ensure access to Chat and User Session lists.
	var chats: [Int:Permissions] = [:]
	var users: [Int:Permissions] = [:]
	
	var chatBlacklist: [Int] = []
	var userBlacklist: [Int] = []
	
	var getChats: [Int:Permissions] { return chats }
	var getUsers: [Int:Permissions] { return users }
  
	public init() { }
	
	/**
	Returns a permissions list for a given Chat ID.  If no permissions exist, 
	a new object is created and catalogued by Moderator.
	*/
	public func getPermissions(chatID: Int) -> Permissions {
		
		if chats[chatID] != nil {
			return chats[chatID]!
		}
		
		else {
			let permissions = Permissions(chatID: chatID)
			chats[chatID] = permissions
			return permissions
		}
	}
	
	/**
	Returns a permissions list for a given Chat ID.  If no permissions exist,
	a new object is created and catalogued by Moderator.
	*/
	public func getPermissions(userID: Int) -> Permissions {
		
		if users[userID] != nil {
			return users[userID]!
		}
			
		else {
			let permissions = Permissions(userID: userID)
			users[userID] = permissions
			return permissions
		}
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
