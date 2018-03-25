//
//  Pelican+Schedule.swift
//  PelicanTests
//
//  Created by Takanu Kyriako on 18/07/2017.
//
//

import Foundation



/**
Organises a list of scheduled events, submitted either by Pelican or a Session to perform at a later date.

Updates by the scheduler are dispatched to the DispatchQueue of the session it belongs to, in order to ensure thread-safe operations.
*/
public class Schedule {
	
	/// A sorted list of events, sorted from the shortest delay to the longest.
	var queue = SynchronizedArray<ScheduleEvent>()
	
	/// The time the run loop was last called at (used for popExpiredEvent)
	var runTime: Date = Date()
	
	/// A callback that allows the Schedule to request that Pelican have the event work be performed on the originating Session's DispatchQueue.
	var requestExecution: (SessionTag, @escaping () -> ()) -> ()
	
	/** 
	The range that the Schedule will look outside the current time to find events to execute on in seconds.
	Useful to account for any loop time fluctuations, defaults to 0.1 seconds.
	*/
	var fluctuationRange: Double = 0.1
	
	
	init(workCallback: @escaping (SessionTag, @escaping () -> ()) -> ()) {
		self.requestExecution = workCallback
	}
	
	
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
		queue.remove(event)
	}
	
	/** 
	Checks to see if an event's time has expired, so it can be removed from the stack.
	*/
	private func popExpiredEvent() -> ScheduleEvent? {
		
		if queue.count == 0 { return nil }
		
		if queue[0]!.executeTime.timeIntervalSince1970 < runTime.timeIntervalSince1970 + fluctuationRange {
			let event = queue[0]!
			queue.remove(at: 0)
			return event
		}
		
		return nil
	}
	
	
	/** 
	Executes all available, expired events in the schedule queue.
	*/
	func run() {
		
		runTime = Date()
		
		while let event = popExpiredEvent() {
			requestExecution(event.tag, event.action)
		}
	}
	
}


/**
Defines a single scheduled item for the Pelican Schedule to execute, at the defined time.
*/
public class ScheduleEvent: Equatable {
	
	// The session the event belongs to, used to appropriately allocate the work to the right DispatchQueue.
	var tag: SessionTag
	
	// The length of the time the event has to wait before it is executed.
	var delay: [Duration]?
	
	// The date at which the event was created.
	public var creationTime: Date { return _creationTime }
	var _creationTime = Date()
	
	// The date at which the event will be executed (rough approximation, seriously rough).
	public var executeTime: Date { return _executeTime }
	var _executeTime: Date
	
	// The action to be executed when the executeTime is reached.
	var action: () -> ()
	
	
	/**
	Creates a Schedule Event using an array of durations as the basis for the execution time.
	*/
	public init(tag: SessionTag, delay: [Duration], action: @escaping () -> ()) {
		
		self.tag = tag
		self.delay = delay
		self.action = action
		
		// Calculate the execution time based on the delay provided
		var shift = 0.0
		for duration in self.delay! {
			shift += duration.unixTime
		}
		
		self._executeTime = _creationTime.addingTimeInterval(shift)
	}
	
	
	/**
	Creates a Schedule Event using an numerical delay value, in Unix Time as the basis for the execution time.
	*/
	public init(tag: SessionTag, delayUnixTime: Double, action: @escaping () -> ()) {
		
		self.tag = tag
		self.action = action
		
		// Append the action delay 
		self._executeTime = _creationTime.addingTimeInterval(delayUnixTime)
	}
	
	
	/**
	Creates a Schedule Event using a specified date as the execution time.
	*/
	public init(tag: SessionTag, atDate: Date, action: @escaping () -> ()) {
		
		self.tag = tag
		self._executeTime = atDate
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
	public func generateExecutionTime() -> Date? {
		
		if self.delay == nil { return nil }
		
		// Calculate the execution time based on the delay provided
		var shift = creationTime
		for duration in self.delay! {
			shift = duration.delayDate(shift)
		}
		
		self._executeTime = shift
		return self.executeTime
		
	}
}




