//
//  UpdateFilter.swift
//  Pelican
//
//  Created by Ido Constantine on 22/03/2018.
//

import Foundation

/**
Records all updates received every time Pelican receives a batch of updates and prevents updates
from being handled by the Session based on criteria you define, such as duplicate forward-slash commands.

UpdateFilter is designed to reduce pressure on your bot and your bot's request limits by dropping updates it
doesn't need to process.

UpdateFilter will not do anything by default, you need to provide it with UpdateFilterCondition types for it to work.

- warning: While a Session will not process the update if it doesn't meet the filter conditions, it
will still count towards a Session's flood limits.

- note: This system is subject to change.
*/
public class UpdateFilter {
	
	var conditions: [UpdateFilterCondition] = []
	
	init() { }
	
	/**
	Verifies whether an update meets the given condition based on the conditions it has.
	- returns: True if it passes all filter condition, false if not.
	*/
	func verifyUpdate(_ update: Update) -> Bool {
		
		for item in conditions {
			if item.verifyUpdate(update) == false { return false }
		}
		
		return true
	}
	
	/**
	Clears the records held for each condition.
	*/
	func clearRecords() {
		conditions.forEach {
			$0.clearRecords()
		}
	}
	
	/**
	Removes all conditions from the filter.
	*/
	func reset() {
		conditions.removeAll()
	}
	
}

/**
A condition for an UpdateFilter type to use when deciding if a received update should be handled by the Session it belongs to.
*/
public class UpdateFilterCondition {
	
	// CONFIGURATION
	/// The type of update this condition applies to
	private var type: UpdateType
	
	/// The range of time the condition will hold on to a set of update records before clearing them.
	var timeRange: Duration
	
	/// The closure that determines whether or not the update can be handled or not.
	private var condition: (UpdateFilterCondition) -> (Bool)
	
	// RECEIVED UPDATES
	/// The updates received so far in this update window.  Records will be added regardless of whether or not they were handled by the Session.
	private var records: [Update] = []
	
	/** The start of the current time window.  If a received update has a time that extends past
	the `timeRange`, it's date will be set as the new start time and the currently held records will be removed. */
	private var recordStartTime = Date()
	
	init(type: UpdateType, timeRange: Duration, condition: @escaping (UpdateFilterCondition) -> (Bool)) {
		self.type = type
		self.timeRange = timeRange
		self.condition = condition
	}
	
	/**
	Verifies whether an update meets the given condition.
	- returns: True if it passes the filter condition, false if not.
	*/
	func verifyUpdate(_ update: Update) -> Bool {
		
		// Check that we're still in a valid time window.
		let diff = update.time.timeIntervalSince1970 - recordStartTime.timeIntervalSince1970
		
		if diff > timeRange.rawValue {
			recordStartTime = update.time
			records.removeAll()
		}
		
		// Now test the condition.
		if self.type != update.type { return true }
		else { return condition(self) }
	}
	
	/**
	Clears the records held.
	*/
	func clearRecords() {
		records.removeAll()
	}
	
}
