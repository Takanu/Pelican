
import Foundation
import Vapor
import FluentProvider

protocol Session {
	
	// CORE DATA
	/// The bot associated with this session, used internally to access the Telegram API.
	var bot: Pelican { get set }
	/** A user-defined type assigned by Pelican on creation, used to cleanly associate custom functionality and
	variables to an individual session.
	*/
	var data: NSCopying? { get set }
	
	// Deletages and controllers
	var permissions: [String] { get }
	
	// TIME AND ACTIVITY
	/// The time the session was first created.
	var timeStarted: Date { get }
	/// The length of time (in seconds) required for the session to be idle or without activity, before it has the potential to be deleted by Pelican.
	var timeoutLength: Int { get set }
	/// The time the session was last active, as a result of it receiving an update.
	var timeLastActive: Date { get }
	
}

extension Session {
	
	/// Defines the permission lists the user is currently on, internally determined by Pelican's Moderator delegate (`bot.mod`).
	public var getPermissions: [String] { return permissions }
	
	/// Returns the time the session was last active, as a result of it receiving an update.
	public var getTimeLastActive: Date { return timeLastActive }
	
	/// Returns whether or not the session has timed out, based on it's timeout limit and the time it was last interacted with.
	public var hasTimeout: Bool {
		
		let calendar = Calendar.init(identifier: .gregorian)
		let comparison = calendar.compare(timeLastActive, to: Date(), toGranularity: .second)
		
		if comparison.rawValue >= timeoutLength && timeoutLength != 0 { return true }
		return false
	}
}





