//
//  Utilities.swift
//  kabuki
//
//  Created by Takanu Kyriako on 24/03/2017.
//
//

import Foundation

internal func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafeBytes(of: &i) { $0.load(as: T.self) }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}

internal class DispatchTimer {
    private let queue = DispatchQueue(label: "timer")
    private let interval: TimeInterval
    private let execute: () -> Void
    private var operation: DispatchWorkItem?
    
    init(interval: TimeInterval, execute: @escaping () -> Void) {
        self.interval = interval
        self.execute = execute
    }
    
    func start() {
        let operation = DispatchWorkItem { [weak self] in
            
            defer { self?.start() }
            self?.execute()
            
        }
        self.operation = operation
        queue.asyncAfter(deadline: .now() + interval, execute: operation)
    }
    func stop() {
        operation?.cancel()
    }
}
