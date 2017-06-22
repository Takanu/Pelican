//
//  SessionRoute.swift
//  party
//
//  Created by Ido Constantine on 22/06/2017.
//
//

import Foundation
import Vapor

/**
Manages all the routes available to a Session at any given time, and routes applicable user requests given to a Session
to any available and matching routes.
*/
public class RouteController {
	
	/**
	The currently active set of routes for the Session.
	- warning: It's recommended to just use the provided functions for editing and removing routes, only use this if
	you need something custom 👌.
	*/
	public var collection: [RequestType:[Route]] = [:]
	
	
	init() {
		collection[.message] = []
		collection[.editedMessage] = []
		collection[.channel] = []
		collection[.editedChannel] = []
		collection[.inlineQuery] = []
		collection[.chosenInlineResult] = []
		collection[.callbackQuery] = []
	}
	
	/**
	Attempts to find and execute a route for the given user request, should only ever be accessed by Session.
	*/
	func routeRequest(content: UserRequest, type: RequestType, session: Session) -> Bool {
		
		var handled = false
		
			
		// Run through all available routes
		for route in collection[type]!	{
			
			// Extract and execute the contained action.
			let action = route.getAction
			
			
			switch action {
			case .message(let actionExec):
				
				// Cast the content to a message type.
				if content is Message {
					let message = content as! Message
					
					// Check that the filter matches
					if route.filter != "" {
						if message.text! != route.filter && message.text != nil {
							continue
						}
					}
					
					// Execute the route
					handled = actionExec(message, session)
				}
				
			case .inlineQuery(let actionExec):
				
				// Cast the content to a inline query type.
				if content is InlineQuery {
					let query = content as! InlineQuery
					
					// Check that the filter matches
					if route.filter != "" {
						if query.query != route.filter {
							continue
						}
					}
					
					// Execute the route
					handled = actionExec(query, session)
				}
				
			case .chosenInlineResult(let actionExec):
				
				// Cast the content to a chosen inline result type.
				if content is ChosenInlineResult {
					let result = content as! ChosenInlineResult
					
					// Check that the filter matches
					if route.filter != "" {
						if result.query != route.filter {
							continue
						}
					}
					
					// Execute the route
					handled = actionExec(result, session)
				}
				
			case .callbackQuery(let actionExec):
				
				// Cast the content to a callback query type.
				if content is CallbackQuery {
					let query = content as! CallbackQuery
					
					// Check that the filter matches
					if route.filter != "" {
						if query.data != route.filter && query.data != nil {
							continue
						}
					}
					
					// Execute the route
					handled = actionExec(query, session)
				}
			}
			
			// If it's been handled by the route, return true
			if handled == true {
				return handled
			}
		}
		
		return handled
	}
	
	
	/** 
	Adds a route to the session, enabling it to be used to receive user requests.  If the session already has a route that 
	matches the one provided in type and filter, it will be overwritten.
	- parameter routes: The routes to be added to the controller.
	*/
	public func add(_ routes: Route...) {
		
		for route in routes {
			var routeArray = collection[route.getType]!
			
			if route.filter != "" {
				
				// If an existing route already exists with the same criteria, remove it.
				if routeArray.first(where: { $0.filter == route.filter } ) != nil {
					
					let index = routeArray.index(where: {$0.filter == route.filter } )!
					routeArray.remove(at: index)
				}
				
				routeArray.insert(route, at: 0)
			}
				
			else {
				routeArray.append(route)
			}
			
			collection[route.getType] = routeArray
		}
	}
	
	/**
	Removes a route based on a given route type and filter name.
	- parameter type: The request target of the route you wish to remove.
	- parameter filter: The filter of the route to be removed.
	- returns: True if a route matched the given criteria and was removed, false if not.
	*/
	public func remove(type: RequestType, filter: String) -> Bool {
		
		var routeSet = collection[type]!
		
		for route in routeSet {
			
			if let index = routeSet.index(where: {$0.filter == filter} ) {
				routeSet.remove(at: index)
				collection[type]! = routeSet
				return true
			}
		}
		
		return false
	}
	
	/**
	Clears all routes of a given request target from the session.
	- parameter type: The request target you wish to clear.
	*/
	public func clear(type: RequestType) {
		collection[type] = []
	}
	
	/**
	Clears all routes of a given type that have no defined filter.  Useful if you have one or two routes
	that act as a default request collector, that due to the current state of the bot require removal.
	*/
	public func clearUnfiltered(type: RequestType) {
		
		var newRouteSet: [Route] = []
		
		for route in collection[type]! {
			
			if route.filter != "" {
				newRouteSet.append(route)
			}
		}
		
		collection[type]! = newRouteSet
	}
	
	
	/**
	Clears all routes for all available user request types.
	*/
	public func clearAll() {
		collection[.message] = []
		collection[.editedMessage] = []
		collection[.channel] = []
		collection[.editedChannel] = []
		collection[.inlineQuery] = []
		collection[.chosenInlineResult] = []
		collection[.callbackQuery] = []
	}
	
}



/**
Defines a single action to be used on a Session RouteController (`session.routes`), to connect user 
requests to bot functionality in a modular and contained way.
*/
public class Route {
	
	/** 
	The route that user responses are compared against, to decide whether or not to use it.
	Leave it blank if the route is dynamic and wishes to receive any already unclaimed responses.
	*/
	public var filter: String = ""
	
	/// The type of user request the route targets.
	private var type: RequestType
	
	/// Retrieves the route type, that determines what kind of user responses it is targeting.
	public var getType: RequestType { return type }
	
	// Privately held actions.  Each route can only have one action, and
	private var action: RouteActionType
	
	/// Retrieves the action associated to the route.
	public var getAction: RouteActionType { return action	}
	
	/**
	Initialises a route with a Message-type action and "Message" user response type.
	*/
	public init(messageRoute: String, action: @escaping (Message, Session) -> (Bool) ) {
		self.filter = messageRoute
		self.type = .message
		self.action = .message(action)
	}
	
	public init(editedMessageRoute: String, action: @escaping (Message, Session) -> (Bool) ) {
		self.filter = editedMessageRoute
		self.type = .editedMessage
		self.action = .message(action)
	}
	
	public init(channelRoute: String, action: @escaping (Message, Session) -> (Bool) ) {
		self.filter = channelRoute
		self.type = .channel
		self.action = .message(action)
	}
	
	public init(editedChannelRoute: String, action: @escaping (Message, Session) -> (Bool) ) {
		self.filter = editedChannelRoute
		self.type = .editedChannel
		self.action = .message(action)
	}
	
	public init(inlineQueryRoute: String, action: @escaping (InlineQuery, Session) -> (Bool) ) {
		self.filter = inlineQueryRoute
		self.type = .inlineQuery
		self.action = .inlineQuery(action)
	}
	
	public init(chosenInlineResultRoute: String, action: @escaping (ChosenInlineResult, Session) -> (Bool) ) {
		self.filter = chosenInlineResultRoute
		self.type = .chosenInlineResult
		self.action = .chosenInlineResult(action)
	}
	
	public init(callbackQueryRoute: String, action: @escaping (CallbackQuery, Session) -> (Bool) ) {
		self.filter = callbackQueryRoute
		self.type = .callbackQuery
		self.action = .callbackQuery(action)
	}
	
}

/**
Defines an available action type that a route can contain.
*/
public enum RouteActionType {
	case message((Message, Session) -> (Bool))
	case inlineQuery((InlineQuery, Session) -> (Bool))
	case chosenInlineResult((ChosenInlineResult, Session) -> (Bool))
	case callbackQuery((CallbackQuery, Session) -> (Bool))
}

/**
Defines the type of request that a route can be assigned to.
*/
public enum RequestType {
	case message
	case editedMessage
	case channel
	case editedChannel
	case inlineQuery
	case chosenInlineResult
	case callbackQuery
}
