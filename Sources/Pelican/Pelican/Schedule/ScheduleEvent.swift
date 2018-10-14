//
//  ScheduleEvent.swift
//  Pelican
//
//  Created by Ido Constantine on 19/04/2018.
//

import Foundation

/**
 Defines a single scheduled item for the Pelican Schedule to execute, at the defined time.
 */
public class ScheduleEvent: Equatable, CustomStringConvertible {
    
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
    
    public var description: String {
        return """
        ScheduleEvent | ID: \(tag.id) | Delay: \(delay ?? [0.sec])
        Created At: \(creationTime) | Planned Execution: \(executeTime)
        """
    }
    
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
