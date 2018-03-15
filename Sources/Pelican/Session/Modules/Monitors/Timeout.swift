//
//  Timeout.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation


/**
Used to monitor timeout conditions for a session.
*/
public class Timeout {
	
	// CALLBACKS
	var tag: SessionTag
	var schedule: Schedule
	
	// CONTROLS
	/// The types that will allow a timeout to get bumped.
	var types: [UpdateType] = []
	
	/// The length of time it takes for a timeout to occur if the timeout controller is not successfully bumped.  If 0 seconds, a timeout will not be triggered.
	var duration: Duration = 0.seconds
	
	/**
	An optional action to be executed if the timeout occurs.
	- note: The session will be removed from Pelican as soon as the action has finished executing, do not queue Schedule events using the session.
	*/
	var action: (() -> ())?
	
	// CURRENT STATE
	/// The last time the timeout time was bumped forwards.
	var lastBump = Date()
	
	/// The last event that was scheduled to trigger a timeout.
	var lastEvent: ScheduleEvent?
	
	
	init(tag: SessionTag, schedule: Schedule) {
		
		self.tag = tag
		self.schedule = schedule
	}
	
	
	/**
	Enable timeouts for the session, which removes the session from the update pool if no updates are received by it within a given timeframe.
	*/
	public func set(updateTypes: [UpdateType], duration: Duration, action: (() -> ())?) {
		
		// Set the properties
		self.types = updateTypes
		self.duration = duration
		self.action = action
		
		// Setup the new Schedule event.
		pushEvent()
	}
	
	
	/**
	Attempts to bump the timeout event further if an update matching the types of updates it considers as
	valid timeout checks are received.
	*/
	public func bump(_ update: Update) {
		
		if types.contains(update.type) == false { return }
		
		// Remove the old event and add the new one.
		pushEvent()
	}
	
	/**
	An internal event for moving the scheduled event for a Timeout to occur further in time.
	*/
	private func pushEvent() {
		
		// Check if a last event exists, and pull it from the schedule.
		if lastEvent != nil {
			schedule.remove(lastEvent!)
		}
		
		// Set the new bump date and event
		lastBump = Date()
		lastEvent = ScheduleEvent(delay: [duration]) {
			
			if self.action != nil {
				self.action!()
			}
			
			self.tag.sendEvent(type: .timeout, action: .remove)
		}
		
		_ = schedule.add(lastEvent!)
	}
	
	/**
	Should be used by the owning Session to clean up requested events before the Session itself closes.
	*/
	public func close() {
		
		if lastEvent != nil {
			schedule.remove(lastEvent!)
		}
		
		reset()
	}
	
	/**
	Resets all Timeout properties to default values.
	*/
	public func reset() {
		self.types = []
		self.duration = 0.sec
		self.action = nil
		
		self.lastBump = Date()
		self.lastEvent = nil
	}
}
