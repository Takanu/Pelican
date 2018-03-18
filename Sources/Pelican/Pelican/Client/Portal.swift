//
//  Result.swift
//  Pelican
//
//  Taken from Vapor's HTTP Module (https://github.com/vapor/engine)
//

import Foundation
import Dispatch

/**
A simple background function that uses dispatch to send a code block to a global queue
*/
public func background(function: @escaping () -> Void) {
	DispatchQueue.global().async(execute: function)
}

/**
There was an error thrown by the portal itself vs a user thrown variable
*/
public enum PortalError: String, Error {
	/**
	Portal was destroyed w/o being closed
	*/
	case notClosed
	
	/**
	Portal timedOut before it was closed.
	*/
	case timedOut
}

/**
A port of Vapor's Portal class (V2.x), defined in their HTTP module to handle the asynchronous nature of URLSession data tasks in a synchronous environment (https://github.com/vapor/engine)
*/
public final class Portal<T> {
	fileprivate var result: Result<T>? = .none
	private let semaphore: DispatchSemaphore
	private let lock = NSLock()
	
	init(_ semaphore: DispatchSemaphore) {
		self.semaphore = semaphore
	}
	
	/**
	Close the portal with a successful result
	*/
	public func close(with value: T) {
		lock.locked {
			guard result == nil else { return }
			result = .success(value)
			semaphore.signal()
		}
	}
	
	/**
	Close the portal with an appropriate error
	*/
	public func close(with error: Error) {
		lock.locked {
			guard result == nil else { return }
			result = .failure(error)
			semaphore.signal()
		}
	}
	
	/**
	Dismiss the portal throwing a notClosed error.
	*/
	public func destroy() {
		semaphore.signal()
	}
}

extension Portal {
	/**
	This function is used to enter an asynchronous supported context with a portal
	object that can be used to complete a given operation.
	
	```
	let value = try Portal<Int>.open { portal in
	// .. do whatever necessary passing around `portal` object
	// eventually call
	
	portal.close(with: 42)
	
	// or
	
	portal.close(with: errorSignifyingFailure)
	}
	```
	
	- parameter timeout: The time that the portal will automatically close if it isn't closed by the handler, in seconds.
	- warning: Calling close on a `portal` multiple times will have no effect.
	*/
	public static func open(
		timeout: Double = (60 * 60),
		_ handler: @escaping (Portal) throws -> Void
		) throws -> T {
		
		// Create the semaphore and portal.
		let semaphore = DispatchSemaphore(value: 0)
		let portal = Portal<T>(semaphore)
		
		// Dispatch the handler work on a global thread.
		background {
			do {
				try handler(portal)
			} catch {
				portal.close(with: error)
			}
		}
		
		// Wait for the portal to signal the semaphore.
		let waitResult = semaphore.wait(timeout: timeout)
		
		// Use the result to decide if we should return or throw an error.
		switch waitResult {
		case .success:
			guard let result = portal.result else { throw PortalError.notClosed }
			return try result.extract()
		case .timedOut:
			throw PortalError.timedOut
		}
	}
}

extension Portal {
	/**
	Execute timeout operations
	*/
	static func timeout(_ timeout: Double, operation: @escaping () throws -> T) throws -> T {
		return try Portal<T>.open(timeout: timeout) { portal in
			let value = try operation()
			portal.close(with: value)
		}
	}
}

extension PortalError {
	public var identifier: String {
		return rawValue
	}
	
	public var reason: String {
		switch self {
		case .notClosed:
			return "the portal finished, but was somehow not properly closed"
		case .timedOut:
			return "the portal timed out before it could finish its operation"
		}
	}
	
	public var possibleCauses: [String] {
		return [
			"user forgot to call `portal.close(with: )`"
		]
	}
	
	public var suggestedFixes: [String] {
		return [
			"ensure the timeout length is adequate for required operation time",
			"make sure that `portal.close(with: )` is being called with an error or valid value"
		]
	}
}
