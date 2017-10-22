//
//  PromptController.swift
//  Pelican
//
//  Created by Takanu Kyriako on 20/08/2017.
//

import Foundation


/** Defines a convenient way to create inline options for users and to provide quick ways of managing and
customising their behaviours.
*/
public class PromptController {
	
	// DATA
	var tag: SessionTag
	var prompts: [Prompt] = []
	
	public var enabled: Bool = true
	public var count: Int { return prompts.count }
	
	
	// CALLBACKS
	var addEvent: (ScheduleEvent) -> ()
	var removeEvent: (ScheduleEvent) -> ()
	
	init(tag: SessionTag, schedule: Schedule) {
		
		self.tag = tag
		self.addEvent = schedule.add(_:)
		self.removeEvent = schedule.remove(_:)
	}
	
	public func add(_ prompt: Prompt) {
		// Check to make sure it doesn't already exist, if it does pull it
		for (index, ownedPrompt) in prompts.enumerated() {
			if ownedPrompt == prompt {
				prompts.remove(at: index)
			}
		}
		
		// Add the prompt to the stack
		prompts.append(prompt)
		prompt.controller = self
	}
	
	/**
	Creates a prompt thats connected to the ChatSession, enabling it to automatically receive callback queries and react to player input,
	as well as to be sent in a chat.  A prompt is a specific model and controller system for defining a message attached to an inline
	message keyboard, including how it's sent and how it reacts to user input.
	- parameter inline: The inline keyboard to be used in this Prompt.
	- parameter text: Either the contents of the message to be sent as part of this prompt, or as a caption if a `FileLink` is also provided.
	- parameter upload: A specific file to be sent as the contents of the message belonging to this prompt.
	- parameter update: (Optional) The closure that is executed every time the prompt receives a callback query.
	*/
	@available(*, deprecated, message: "Prompts are unreliable, clunky and likely to cause memory leaks - use a combination of custom Route types and functions instead.")
	public func createPrompt(name: String, inline: MarkupInline, text: String, file: MessageFile?, update: ((Prompt) -> ())? ) -> Prompt {
		let prompt = Prompt(controller: self, name: name, inline: inline, text: text, file: file, update: update)
		prompt.controller = self
		self.add(prompt)
		return prompt
	}
	
	/** Attempts to retrieve a prompt with a given name.
	*/
	public func get(withName name: String) -> Prompt? {
		for prompt in prompts {
			if prompt.name == name {
				return prompt
			}
		}
		
		return nil
	}
	
	/** Finds a prompt that matches the given query.
	*/
	public func search(withQuery query: CallbackQuery) -> Prompt? {
		for prompt in prompts {
			if prompt.message != nil {
				if prompt.message!.tgID == query.message?.tgID {
					return prompt
				}
			}
		}
		
		return nil
	}
	
	/** Filters a query for a prompt to receive and handle.
	*/
	func handle(_ update: Update) -> Bool {
		
		// Return if basic update conditions aren't met
		if enabled == false { return false }
		if update.type != .callbackQuery { return false }
		
		let query = update.data as! CallbackQuery
		
		for prompt in prompts {
			if prompt.message != nil {
				if prompt.message!.tgID == query.message?.tgID {
					
					let handled = prompt.query(update: update)
					if handled == true {
						return true
					}
				}
			}
		}
		
		return false
	}
	
	/** Finds a prompt that matches the given query.
	*/
	public func remove(_ prompt: Prompt) {
		// Check to make sure it doesn't already exist, if it does pull it
		for (index, ownedPrompt) in prompts.enumerated() {
			if ownedPrompt == prompt {
				//prompt.close()
				prompts.remove(at: index)
				return
			}
		}
	}
	
	/** Removes all prompts from the system.
	*/
	public func removeAll() {
		prompts.forEach( {$0.close(finalText: $0.text, finalMarkup: $0.inline) } )
		prompts.removeAll()
	}
}
