//
//  Pelican+Queues.swift
//  Pelican
//
//  Created by Takanu Kyriako on 04/03/2018.
//

import Foundation
import Dispatch     // Required on Linux platforms.


// The Dispatch queue for getting updates and serving them to sessions.
class LoopQueue {
	
	/// The actual dispatch queue, that uses the highest level of QoS.
	private let queue: DispatchQueue
	
	/// The minimum length of time that must be between the start of the code block and the end of it, before it is called again.
	private let interval: TimeInterval
	
	/// The time the current code block was executed.
	private var startTime: Date
	
	/// The length of time it took for the code block to fully execute.
	private var lastExecuteLength: TimeInterval
	
	/// The code block to be executed by the queue.
	private let execute: () -> Void
	
	/// The work item that encapsulates the `execute` closure property, which is the item pushed to the queue
	private var operation: DispatchWorkItem?
	
	init(queueLabel: String,
			 qos: DispatchQoS,
			 interval: TimeInterval,
			 execute: @escaping () -> Void) {
		
		self.queue = DispatchQueue(label: queueLabel,
															 qos: qos,
															 target: nil)
		
		self.interval = interval
		self.startTime = Date()
		self.lastExecuteLength = TimeInterval.init(0)
		self.execute = execute
		self.operation = DispatchWorkItem(qos: qos, flags: .enforceQoS) { [weak self] in
			
			// Record the starting time and execute the loop
			self?.startTime = Date()
			self?.execute()
			self?.queueNext()
		}
	}
	
	/**
	The function that should be called when the code block finishes executing on the queue, to determine when to
	schedule the next code block execution.
	*/
	func queueNext() {
		lastExecuteLength = abs(startTime.timeIntervalSinceNow)
		
		// Account for loop time in the asynchronous delay.
		let delayTime = interval - lastExecuteLength
		
		// If the delay time left is below 0, execute the loop immediately.
		if delayTime <= 0 {
			//PLog.verbose("Update loop executing immediately.")
			queue.async(execute: self.operation!)
		}
			
			// Otherwise use the built delay time.
		else {
			//PLog.verbose("Update loop executing at \(DispatchWallTime.now() + delayTime)")
			queue.asyncAfter(wallDeadline: .now() + delayTime, execute: self.operation!)
		}
	}
	
	/**
	Cancels the execution of the `operation` work item, if currently being executed by the queue.
	*/
	func stop() {
		operation?.cancel()
		PLog.warning("Update cycle cancelled")
	}
}
