//
//  Pelican+Schedule.swift
//  PelicanTests
//
//  Created by Ido Constantine on 18/07/2017.
//
//

import Foundation
import Vapor


/**
Defines a list of scheduled events, submitted either by Pelican or a Session to perform at a later date.
*/
public class Schedule {
	
	/// A sorted list of events, sorted from the shortest delay to the longest.
	var queue: [ScheduleEvent] = []
	/// The time the run loop was last called at (used for popExpiredEvent)
	var runTime: Date = Date()
	
	/** 
	The range that the Schedule will look outside the current time to find events to execute on in seconds.
	Useful to account for any loop time fluctuations, defaults to 0.1 seconds.
	*/
	var fluctuationRange: Double = 0.1
	
	
	
	
	init() { }
	
	
	/**
	Adds an event to the queue.
	*/
	func add(_ event: ScheduleEvent) {
		
		if let index = queue.index(where: { $0.executeTime.timeIntervalSince1970 > event.executeTime.timeIntervalSince1970 } ) {
			queue.insert(event, at: index)
		}
		
		else {
			queue.append(event)
		}
		
	}
	
	/**
	Removes an event from the queue if it matches the event used as an argument.
	*/
	func remove(_ event: ScheduleEvent) {
		
		if let index = queue.index(where: { $0 == event } ) {
			queue.remove(at: index)
		}
	}
	
	/** 
	Checks to see if an event's time has expired, so it can be removed from the stack.
	*/
	private func popExpiredEvent() -> ScheduleEvent? {
		
		if queue.count == 0 { return nil }
		
		if queue[0].executeTime.timeIntervalSince1970 < runTime.timeIntervalSince1970 + fluctuationRange {
			return queue.remove(at: 0)
		}
		
		return nil
	}
	
	
	/** 
	Executes all available, expired events in the schedule queue.
	*/
	func run() {
		
		runTime = Date()
		
		while let event = popExpiredEvent() {
			event.action()
		}
	}
	
}


/**
Defines a single scheduled item for the Pelican Schedule to execute, at the defined time.
*/
public class ScheduleEvent: Equatable {
	
	var delay: [Duration]?
	var creationTime = Date()
	var executeTime: Date
	
	var action: () -> ()
	
	
	/**
	Creates a Schedule Event using an array of durations as the basis for the execution time.
	*/
	init(delay: [Duration], action: @escaping () -> ()) {
		
		// Set the basic properties
		self.delay = delay
		self.action = action
		
		// Calculate the execution time based on the delay provided
		var shift = creationTime
		for duration in self.delay! {
			shift = duration.delayDate(shift)
		}
		
		self.executeTime = shift
	}
	
	
	/**
	Creates a Schedule Event using an numerical delay value, in Unix Time as the basis for the execution time.
	*/
	init(delayUnixTime: Double, action: @escaping () -> ()) {
		
		// Set the basic properties
		self.action = action
		
		// Append the action delay
		self.executeTime = creationTime.addingTimeInterval(delayUnixTime)
		print(self.executeTime)
	}
	
	
	/**
	Creates a Schedule Event using a specified date as the execution time.
	*/
	init(atDate: Date, action: @escaping () -> ()) {
		
		// Set the basic properties
		self.executeTime = atDate
		self.action = action
	}
	
	
	
	public static func ==(lhs: ScheduleEvent, rhs: ScheduleEvent) -> Bool {
		
		if lhs.delay != nil && rhs.delay != nil {
			if lhs.delay!.elementsEqual(rhs.delay!) &&
				 lhs.creationTime == rhs.creationTime &&
			   lhs.executeTime == rhs.executeTime { return true }
		}
		
		else if lhs.delay == nil && rhs.delay == nil  &&
			 lhs.creationTime == rhs.creationTime &&
			 lhs.executeTime == rhs.executeTime { return true }
		
		return false
		
	}
	
	/**
	Based on the current time, generate an accurate execution time for the event.  This
	only works if the event has a delay `Duration` set.
	*/
	func generateExecutionTime() -> Date? {
		
		if self.delay == nil { return nil }
		
		// Calculate the execution time based on the delay provided
		var shift = creationTime
		for duration in self.delay! {
			shift = duration.delayDate(shift)
		}
		
		self.executeTime = shift
		return self.executeTime
		
	}
}




