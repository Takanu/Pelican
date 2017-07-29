
import Foundation
import Vapor






/**
Manages user access to the bot through a permanent blacklist feature (that works in conjunction with FloodLimit), while
enabling the creation of custom user lists for flexible permission and other custom user and chat grouping systems.
*/
public class Moderator {
	
	/// Holds the main bot class to ensure access to Chat and User Session lists.
	var chatTitles: [String:[Int]] = [:]
	var userTitles: [String:[Int]] = [:]
	
	var chatBlacklist: [Int] = []
	var userBlacklist: [Int] = []
	
	var getChats: [String:[Int]] { return chatTitles }
	var getUsers: [String:[Int]] { return userTitles }
  
	public init() { }
	
	
	
	/**
	An internal function to do the heavy lifting for tag changes.
	*/
	func switchTitle(type: SessionIDType, title: String, ids: [Int], remove: Bool) {
		
		
		func editList(ids: [Int], list: [Int], remove: Bool) -> [Int] {
			
			var mutableList: [Int] = list
			
			if remove == true {
				
				ids.forEach( {
					if let index = mutableList.index(of: $0) {
						mutableList.remove(at: index)
					}
				})
			}
				
			else {
				
				ids.forEach( {
					if mutableList.contains($0) == false {
						mutableList.append($0)
					}
				})
			}
			
			return mutableList
		}
		
		
		switch type {
			
		case .chat:
			
			if chatTitles[title] == nil {
				chatTitles[title] = []
			}
			
			let list = chatTitles[title]!
			chatTitles[title] = editList(ids: ids, list: list, remove: remove)
			
			if chatTitles[title]!.count == 0 {
				chatTitles.removeValue(forKey: title)
			}
			
		case .user:
			
			if userTitles[title] == nil {
				userTitles[title] = []
			}
			
			let list = userTitles[title]!
			userTitles[title] = editList(ids: ids, list: list, remove: remove)
			
			if userTitles[title]!.count == 0 {
				userTitles.removeValue(forKey: title)
			}
			
		default:
			return
		}
	}
	
	/**
	Returns the currently used titles.
	*/
	public func getTitles(forType type: SessionIDType) -> [String]? {
		
		switch type {
			
		case .chat:
			return chatTitles.keys.array
			
		case .user:
			return userTitles.keys.array
			
		default:
			return nil
		}
	}
	
	/**
	Returns the titles associated to a specific ID.
	*/
	public func getTitles(forID id: Int, type: SessionIDType) -> [String] {
		
		var titles: [String] = []
		
		switch type {
			
		case .chat:
			chatTitles.forEach( {
				if $0.value.contains(id) == true { titles.append($0.key) }
			} )
			
		case .user:
			userTitles.forEach( {
				if $0.value.contains(id) == true { titles.append($0.key) }
			} )
			
		default:
			return []
		}
		
		return titles
	}
	
	/**
	Returns the IDs associated to a specific title.
	*/
	public func getIDs(forTitle title: String, type: SessionIDType) -> [Int]? {
		
		switch type {
			
		case .chat:
			
			if let ids = chatTitles[title] {
				return ids
			}
			
		case .user:
			
			if let ids = userTitles[title] {
				return ids
			}
			
		default:
			return nil
		}
		
		return nil
	}
	
	
	/**
	Adds a given set of IDs to a specific title.
	*/
	public func addIDs(forTitle title: String, type: SessionIDType, ids: Int...) {
		
		switchTitle(type: type, title: title, ids: ids, remove: false)
	}
	
	/**
	Removes a given set of IDs from a specific title.
	*/
	public func removeIDs(forTitle title: String, type: SessionIDType, ids: Int...) {
		
		switchTitle(type: type, title: title, ids: ids, remove: true)
	}
	
	
	
	// BLACKLIST
	
	/**
	Adds the given users to the blacklist, preventing their updates from being received by or propogating any sessions.
	As this function does not remove and close the Session, this is an internal type only.
	*/
	func addToBlacklist(userIDs: Int...) {
		
		// Add the users to the blacklist if they aren't already there
		for id in userIDs {
			
			if userBlacklist.contains(id) == false {
				userBlacklist.append(id)
			}
		}
	}
	
	
	/**
	Adds the given chats to the blacklist, preventing their updates from being received by or propogating any sessions.
	As this function does not remove and close the Session, this is an internal type only.
	*/
	func addToBlacklist(chatIDs: Int...) {
		
		// Add the chats to the blacklist if they aren't already there
		for id in chatIDs {
			
			if chatBlacklist.contains(id) == false {
				chatBlacklist.append(id)
				print("ADDED TO BLACKLIST - \(id)")
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
