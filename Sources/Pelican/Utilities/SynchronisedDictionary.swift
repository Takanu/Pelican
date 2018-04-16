//
//  SynchronisedDictionary.swift
//  Pelican
//

import Foundation
import Dispatch     // Linux thing.

/**
A dictionary that allows for thread-safe concurrent access.
- warning: This is not yet feature complete, and only supports a small number
of the in-built methods and properties that a normal dictionary supports.
*/
public class SynchronisedDictionary<KeyType: Hashable, ValueType> {
	
	typealias Key = KeyType
	typealias Value = ValueType
	
	/// The name of the dictionary, used when making the queue to identify it for debugging purposes.
	public private(set) var name: String?
	
	/// The internal dictionary that this class gates access to across threads.
	private var internalDictionary: [KeyType: ValueType] = [:]
	
	/// The queue used to order and execute read/write operations on the dictionary.
	private let queue: DispatchQueue
	
	init(name: String? = nil) {
		self.name = name
		
		var queueLabel = ""
		if name != nil {
			queueLabel = "com.Pelican.SynthronizedDictionary.\(name!)"
		} else {
			queueLabel = "com.Pelican.SynthronizedDictionary"
		}
		self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
		
	}
}

// MARK: - Properties
public extension SynchronisedDictionary {
	
	/// The first element of the collection.
	var first: (key: KeyType, value: ValueType)? {
		var result: (key: KeyType, value: ValueType)?
		queue.sync { result = self.internalDictionary.first }
		return result
	}
	
	/// The number of elements in the dictionary.
	var count: Int {
		var result = 0
		queue.sync { result = self.internalDictionary.count }
		return result
	}
	
	/// A Boolean value indicating whether the collection is empty.
	var isEmpty: Bool {
		var result = false
		queue.sync { result = self.internalDictionary.isEmpty }
		return result
	}
	
	/// A textual representation of the dictionary and its elements.
	var description: String {
		var result = ""
		queue.sync { result = self.internalDictionary.description }
		return result
	}
}


extension SynchronisedDictionary {
	
	////////////////
	// SUBSCRIPT
	
	subscript(key: KeyType) -> ValueType? {
		get {
			var result: ValueType?
			queue.sync {
				result = internalDictionary[key]
			}
			return result
		}
		
		set {
			guard let newValue = newValue else { return }
			
			queue.async(flags: .barrier) {
				self.internalDictionary[key] = newValue
			}
		}
	}
}

// MARK: - Immutable
public extension SynchronisedDictionary {
	
	/// Calls the given closure on each element in the sequence in the same order as a for-in loop.
	///
	/// - Parameter body: A closure that takes a key-value pair of the sequence as a parameter.
	func forEach(_ body: ((key: KeyType, value: ValueType)) throws -> Void) rethrows {
		try queue.sync { try self.internalDictionary.forEach(body) }
	}
	
}

// MARK: - Mutable
public extension SynchronisedDictionary {
	
	func removeValue(forKey key: KeyType, completion: ((ValueType?) -> Void)? = nil) {
		queue.async(flags: .barrier) {
			let value = self.internalDictionary.removeValue(forKey: key)
			
			DispatchQueue.main.async {
				completion?(value)
			}
		}
	}
	
	/// Removes all elements from the array.
	///
	func removeAll() {
		queue.async(flags: .barrier) {
			self.internalDictionary.removeAll()
		}
	}

}
