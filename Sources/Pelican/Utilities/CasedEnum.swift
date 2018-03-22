//
//  CasedEnum.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/10/2017.
//

import Foundation

/**
Defines convenience iteration and string extraction methods for various enumeration types, such as UpdateType.
*/
public protocol CasedEnum : Hashable {
	
	func string() -> String
}

extension CasedEnum {
	static func cases() -> AnySequence<Self> {
		typealias S = Self
		return AnySequence { () -> AnyIterator<S> in
			var raw = 0
			return AnyIterator {
				let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
				guard current.hashValue == raw else { return nil }
				raw += 1
				return current
			}
		}
	}
}
