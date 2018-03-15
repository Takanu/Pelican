//
//  SessionDispatchQueue.swift
//  App
//
//  Created by Ido Constantine on 05/03/2018.
//

import Foundation
import Dispatch     // Required on Linux platforms.

/**
Encapsulates a DispatchQueue with a synchronised array of all work currently queued to it.
Allows for all work queued on a DispatchQueue to be cancelled without race conditions or manual work comparison.
*/
public class SessionDispatchQueue {
	
	/// The current queue of DispatchWorkItems waiting to be executed.
	private var workItems = SynchronizedArray<DispatchWorkItem>()
	
	/// The DispatchQueue used to queue update handler work.
	private var queue: DispatchQueue
	
	init(tag: SessionTag, label: String, qos: DispatchQoS) {
		self.queue = DispatchQueue(label: "\(label)-\(tag.id)",
															 qos: qos,
															 autoreleaseFrequency: .inherit,
															 target: nil)
	}
	
	/**
	Wraps a DispatchWorkItem around the given block set at the same QoS level as the DispatchQueue, and adds it to the queue to be executed.
	*/
	public func async(_ block: @escaping () -> ()) {
		
		/// Wraps the block around a request to remove the first item in the work queue.
		let newWorkBlock = {
			self.workItems.remove(at: 0)
			block()
		}
		
		let newWorkItem = DispatchWorkItem(qos: queue.qos,
																		flags: .inheritQoS,
																		block: newWorkBlock)
		
		workItems.append(newWorkItem)
		queue.async(execute: newWorkItem)
	}
	
	/**
	Cancels all DispatchWorkItems not currently being executed by the queue.
	*/
	public func cancelAll() {
		workItems.forEach {
			$0.cancel()
		}
	}
}
