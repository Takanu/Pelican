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
        if queue[0] == nil { return nil }
		
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






