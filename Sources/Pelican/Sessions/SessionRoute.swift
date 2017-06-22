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
Enables the sorting and responding of user requests using a modular routing system, matching user requests to routes.

Routes can be specific or ambiguous, and can be provided for any type of interaction a user can have with your bot.
*/
public class RouteController {
	
	private var routes: [RequestType:[Route]] = [:]
	
	
	init() {
		routes[.message] = []
		routes[.editedMessage] = []
		routes[.channel] = []
		routes[.editedChannel] = []
		routes[.inlineQuery] = []
		routes[.chosenInlineResult] = []
		routes[.callbackQuery] = []
	}
	
	/**
	Attempts to find and execute a route for the given user request, should only ever be accessed by Session.
	*/
	func routeRequest(content: UserRequest, type: RequestType, session: Session) -> Bool {
		
		var handled = false
		
			
		// Run through all available routes
		for route in routes[type]!	{
			
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
	- parameter route: The route to be added to the controller.
	*/
	public func add(_ route: Route) {
		
		var routeArray = routes[route.getType]!
		
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
		
		routes[route.getType] = routeArray
	}
	
	/**
	Clears all routes of a given type from the session.
	*/
	public func clear(type: RequestType) {
		routes[type] = []
	}
	
	/**
	Clears all routes.  All of them
	*/
	public func clearAll() {
		routes[.message] = []
		routes[.editedMessage] = []
		routes[.channel] = []
		routes[.editedChannel] = []
		routes[.inlineQuery] = []
		routes[.chosenInlineResult] = []
		routes[.callbackQuery] = []
	}
	
}



/**
Defines a specific route that can be assigned to a session to match user requests to specific bot functionality.

Routes can be specific or ambiguous, and can be provided for any type of interaction a user can have with your bot.
*/
public class Route {
	
	/** The route that user responses are compared against, to decide whether or not to use it.
	Leave it blank if the route is dynamic and wishes to receive any already unclaimed responses.
	*/
	public var filter: String = ""
	private var type: RequestType
	
	/// Retrieves the route type, that determines what kind of user responses it is targeting.
	public var getType: RequestType { return type }
	
	// Privately held actions.  Each route can only have one action, and
	private var action: RouteActionType
	
	/// Retrieves the action associated to the route.
	public var getAction: RouteActionType { return action	}
	
	
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

public enum RouteActionType {
	case message((Message, Session) -> (Bool))
	case inlineQuery((InlineQuery, Session) -> (Bool))
	case chosenInlineResult((ChosenInlineResult, Session) -> (Bool))
	case callbackQuery((CallbackQuery, Session) -> (Bool))
}

public enum RequestType {
	case message
	case editedMessage
	case channel
	case editedChannel
	case inlineQuery
	case chosenInlineResult
	case callbackQuery
}
