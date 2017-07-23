//
//  Pelican+Duration.swift
//  PelicanTests
//
//  Created by Ido Constantine on 18/07/2017.
//
//

import Foundation

/**
Pinched as a concept from the Jobs Swift module as a way to cleanly define types of time (https://github.com/BrettRToomey/Jobs).
*/
public enum Duration: Equatable {
	
	case seconds(Double)
	case minutes(Int)
	case hours(Int)
	case days(Int)
	case weeks(Int)
	
	/**
	Given a date, this function will delay it by the amount specified in this Duration.
	- returns: A new `Date` type, delayed by the Duration.
	*/
	func delayDate(_ date: Date) -> Date {
		
		// Break down the current date into components.
		let calendar = Calendar.current
		var components = calendar.dateComponents([.month, .weekday, .day, .hour, .minute, .second, .nanosecond], from: date)
		
		switch self {
			
		case .seconds(let time):
			let second = Int(time.rounded(.down))
			let nanosecond = Int(time.remainder(dividingBy: 1) * 10000)
			
			components.setValue(second + components.second!, for: .second)
			components.setValue(nanosecond + components.nanosecond!, for: .nanosecond)
			
		case .minutes(let time):
			components.setValue(Int(time) + components.second!, for: .minute)
			
		case .hours(let time):
			components.setValue(Int(time) + components.second!, for: .hour)
			
		case .days(let time):
			components.setValue(Int(time) + components.second!, for: .day)
			
		case .weeks(let time):
			components.setValue(Int(time) + components.second!, for: .weekday)
			
		}
		
		return calendar.date(from: components)!
	}
	
	
	
	public static func ==(lhs: Duration, rhs: Duration) -> Bool {
		
		if lhs.type == rhs.type && lhs.rawValue == rhs.rawValue { return true }
		
		return false
	}
	
}


extension Duration {
	
	/**
	Returns the duration value type, as a string (mainly for internal comparisons).
	*/
	public var type: String {
		
		switch self {
			
		case .seconds(_):
			return "seconds"
		case .minutes(_):
			return "minutes"
		case .hours(_):
			return "hours"
		case .days(_):
			return "days"
		case .weeks(_):
			return "weeks"
			
		}
	}
	
	/**
	Returns the raw numerical value stored as a duration in the enumerator, as a double (mainly for internal comparisons).
	*/
	public var rawValue: Double {
		
		switch self {
			
		case .seconds(let time):
			return time
		case .minutes(let time):
			return Double(time)
		case .hours(let time):
			return Double(time)
		case .days(let time):
			return Double(time)
		case .weeks(let time):
			return Double(time)
			
		}
	}
	
	/// Converts the enumeration representation of time into a `Double`.
	public var unixTime: Double {
		
		switch self {
			
		case .seconds(let count):
			return count
			
		case .minutes(let count):
			
			let secondsInMinute = 60
			return Double(count * secondsInMinute)
			
		case .hours(let count):
			
			let secondsInHour = 3_600
			return Double(count * secondsInHour)
			
		case .days(let count):
			let secondsInDay = 86_400
			return Double(count * secondsInDay)
			
		case .weeks(let count):
			let secondsInWeek = 604_800
			return Double(count * secondsInWeek)
		}
	}
}


extension Int {
	/// Converts the integer into an enum representation of seconds.
	public var seconds: Duration {
		return .seconds(Double(self))
	}
	
	/// Converts the integer into an enum representation of minutes.
	public var minutes: Duration {
		return .minutes(self)
	}
	
	/// Converts the integer into an enum representation of hours.
	public var hours: Duration {
		return .hours(self)
	}
	
	/// Converts the integer into an enum representation of days.
	public var days: Duration {
		return .days(self)
	}
	
	/// Converts the integer into an enum representation of weeks.
	public var weeks: Duration {
		return .weeks(self)
	}
}

extension Double {
	/// Converts the real into an enum representation of seconds.
	public var seconds: Duration {
		return .seconds(self)
	}
}
