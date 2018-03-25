//
//  Builder+Spawn.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation


/**
Defines a collection of functions that generate filtering closures.

A function that's used as a Spawner must always return a function of type `(Update) -> String?`.
*/
public class Spawn {
	
	/**
	A spawner that returns Chat IDs, that are tied to specific update types, originating from specific chat types.
	- parameter updateType: The update types the spawner is looking for.  If nil, all update types will be accepted.
	- parameter chatType: The types of chat the update originated from that the spawner is looking for.  If nil, all chat types will be accepted.
	*/
	public static func perChatID(updateType: [UpdateType]?, chatType: [ChatType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.chat == nil { return nil }
			
			if updateType != nil {
				if updateType!.contains(update.type) == false { return nil }
			}
			
			if chatType != nil {
				if chatType!.contains(update.chat!.type) == false { return nil }
			}
			
			return update.chat!.tgID
		}
		
	}
	
	/**
	A spawner that returns Chat IDs if they both match the inclusion list and the defined update and chat types.
	- parameter include: The Chat IDs that are allowed to pass-through this spawner.
	- parameter updateType: The update types the spawner is looking for.  If nil, all update types will be accepted.
	- parameter chatType: The types of chat the update originated from that the spawner is looking for.  If nil, all chat types will be accepted.
	*/
	public static func perChatID(include: [Int], updateType: [UpdateType]?, chatType: [ChatType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.chat == nil { return nil }
			
			if include.count > 0 {
				if include.contains(update.chat!.tgID) == false { return nil }
			}
			
			if updateType != nil {
				if updateType!.contains(update.type) == false { return nil }
			}
			
			if chatType != nil {
				if chatType!.contains(update.chat!.type) == false { return nil }
			}
			
			return update.chat!.tgID
		}
	}
	
	/**
	A spawner that returns Chat IDs if they both **do not** match the excluision list, and that match the defines update and chat types.
	- parameter exclude: The Chat IDs that are not allowed to pass-through this spawner.
	- parameter updateType: The update types the spawner is looking for.  If nil, all update types will be accepted.
	- parameter chatType: The types of chat the update originated from that the spawner is looking for.  If nil, all chat types will be accepted.
	*/
	public static func perChatID(exclude: [Int], updateType: [UpdateType]?, chatType: [ChatType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.chat == nil { return nil }
			
			if exclude.count > 0 {
				if exclude.contains(update.chat!.tgID) == true { return nil }
			}
			
			if updateType != nil {
				if updateType!.contains(update.type) == false { return nil }
			}
			
			if chatType != nil {
				if chatType!.contains(update.chat!.type) == false { return nil }
			}
			
			return update.chat!.tgID
		}
	}
	
	public static func perUserID(updateType: [UpdateType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.from == nil { return nil }
			if updateType == nil { return update.from!.tgID }
			else if updateType!.contains(update.type) == true { return update.from!.tgID }
			return nil
		}
	}
	
	public static func perUserID(include: [Int], updateType: [UpdateType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.chat == nil { return nil }
			
			if include.count > 0 {
				if include.contains(update.from!.tgID) == false { return nil }
			}
			
			if updateType != nil {
				if updateType!.contains(update.type) == false { return nil }
			}
			
			return update.from!.tgID
		}
	}
	
	public static func perUserID(exclude: [Int], updateType: [UpdateType]?) -> ((Update) -> Int?) {
		
		return { update in
			
			if update.chat == nil { return nil }
			
			if exclude.count > 0 {
				if exclude.contains(update.from!.tgID) == true { return nil }
			}
			
			if updateType != nil {
				if updateType!.contains(update.type) == false { return nil }
			}
			
			return update.from!.tgID
		}
	}
}
