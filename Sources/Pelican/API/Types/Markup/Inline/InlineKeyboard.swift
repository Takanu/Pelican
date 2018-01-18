//
//  Inline.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/**
Represents a series of inline buttons that will be displayed underneath the message when included with it.

Each inline button can do one of the following:
_ _ _ _ _

**Callback Data**

This sends a small String back to the bot as a `CallbackQuery`, which is automatically filtered
back to the session and to a `callbackState` if one exists.

Alternatively if the keyboard the button belongs to is part of a `Prompt`, it will automatically
be received by it in the respective ChatSession, and the prompt will respond based on how you have set
it up.

**URL**

The button when pressed will re-direct users to a webpage.

**Inine Query Switch**

This can only be used when the bot supports Inline Queries.  This prompts the user to select one of their chats
to open it, and when open the client will insert the bot‘s username and a specified query in the input field.

**Inline Query Current Chat**

This can only be used when the bot supports Inline Queries.  Pressing the button will insert the bot‘s username
and an optional specific inline query in the current chat's input field.

*/
final public class MarkupInline: MarkupType, Codable, Equatable {
	
	public var keyboard: [[MarkupInlineKey]] = []
	
	
	
	// Blank!
	public init() {
		return
	}
	
	/**
	Creates an Inline Keyboard using a series of specified `MarkupInlineKey` types, where all buttons will
	be arranged on a single row.
	- parameter buttonsIn: The buttons to be included in the keyboard.
	*/
	public init(withButtons buttonsIn: MarkupInlineKey...) {
		var array: [MarkupInlineKey] = []
		
		for button in buttonsIn {
			array.append(button)
		}
		
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and URL string pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/url String tuples that will define each key on the keyboard.
	*/
	public init(withURL sequence: (url: String, text: String)...) {
		var array: [MarkupInlineKey] = []
		
		for tuple in sequence {
			let button = MarkupInlineKey(fromURL: tuple.url, text: tuple.text)
			array.append(button)
		}
		
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and callback String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/callback String tuples that will define each key on the keyboard.
	*/
	public init?(withCallback sequence: (query: String, text: String?)...) {
		var array: [MarkupInlineKey] = []
		
		for tuple in sequence {
			
			// Try to process them, but propogate the error if it fails.
			guard let button = MarkupInlineKey(fromCallbackData: tuple.query, text: tuple.text) else {
				return nil
			}
			
			array.append(button)
		}
		
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using sets of arrays containing label and callback tuples, where each tuple array
	is a single row.
	- parameter array: A an array of label/callback String tuple arrays that will define each row on the keyboard.
	*/
	public init?(withCallback array: [[(query: String, text: String)]]) {
		for row in array {
			var array: [MarkupInlineKey] = []
			for tuple in row {
				
				// Try to process them, but propogate the error if it fails.
				guard let button = MarkupInlineKey(fromCallbackData: tuple.query, text: tuple.text) else {
					return nil
				}
				
				array.append(button)
			}
			keyboard.append(array)
		}
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query Current Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query Current Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryCurrent sequence: (query: String, text: String)...) {
		var array: [MarkupInlineKey] = []
		for tuple in sequence {
			let button = MarkupInlineKey(fromInlineQueryCurrent: tuple.query, text: tuple.text)
			array.append(button)
		}
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of specified button label and "Inline Query New Chat" String pairs, where all buttons will
	be arranged on a single row.
	- parameter pair: A sequence of label/"Inline Query New Chat" String tuples that will define each key on the keyboard.
	*/
	public init(withInlineQueryNewChat sequence: (query: String, text: String)...) {
		var array: [MarkupInlineKey] = []
		for tuple in sequence {
			let button = MarkupInlineKey(fromInlineQueryNewChat: tuple.query, text: tuple.text)
			array.append(button)
		}
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a series of labels.  The initializer will then generate an associated ID value for each
	label and assign it to the button as Callback data, starting with "1" and incrementing upwards.
	
	All buttons wil be arranged on a single row.
	
	- parameter labels: A sequence of String labels that will define each key on the keyboard.
	*/
	public init?(withGenCallback sequence: String...) {
		var array: [MarkupInlineKey] = []
		var id = 1
		
		for label in sequence {
			guard let button = MarkupInlineKey(fromCallbackData: String(id), text: label) else {
				return nil
			}
			
			array.append(button)
			id += 1
		}
		
		keyboard.append(array)
	}
	
	/**
	Creates an Inline Keyboard using a set of nested String Arrays, where the array structure defines the specific arrangement
	of the keyboard.
	
	The initializer will generate an associated ID value for eachlabel and assign it to the button as Callback data, starting
	with "1" and incrementing upwards.
	
	- parameter rows: A nested set of String Arrays, where each String array will form a single row on the inline keyboard.
	*/
	public init?(withGenCallback rows: [[String]]) {
		
		var id = 1
		for row in rows {
			var array: [MarkupInlineKey] = []
			
			for label in row {
				guard let button = MarkupInlineKey(fromCallbackData: String(id), text: label) else {
					return nil
				}
				
				array.append(button)
				id += 1
			}
			keyboard.append(array)
		}
		
	}
	
	/**
	Adds an extra row to the keyboard using the sequence of buttons provided.
	*/
	public func addRow(sequence: MarkupInlineKey...) {
		var array: [MarkupInlineKey] = []
		
		for button in sequence {
			array.append(button)
		}
		
		keyboard.append(array)
	}
	
	/**
	Adds extra rows to the keyboard based on the array of buttons you provide.
	*/
	public func addRow(array: [MarkupInlineKey]...) {
		
		for item in array {
			keyboard.append(item)
		}
	}
	
	
	/**
	Returns all available callback data from any button held inside this markup
	*/
	public func getCallbackData() -> [String]? {
		var data: [String] = []
		for row in keyboard {
			for key in row {
				
				if key.type == .callbackData {
					data.append(key.data)
				}
			}
		}
		
		return data
	}
	
	/**
	Returns all labels associated with the inline keyboard.
	*/
	public func getLabels() -> [String] {
		var labels: [String] = []
		for row in keyboard {
			for key in row {
				labels.append(key.text)
			}
		}
		
		return labels
	}
	
	/**
	Returns the label thats associated with the provided data, if it exists.
	*/
	public func getLabel(withData data: String) -> String? {
		for row in keyboard {
			for key in row {
				
				if key.data == data { return key.text }
			}
		}
		
		return nil
	}
	
	/**
	Returns the key thats associated with the provided data, if it exists.
	*/
	public func getKey(withData data: String) -> MarkupInlineKey? {
		for row in keyboard {
			for key in row {
				
				if key.data == data { return key }
			}
		}
		
		return nil
	}
	
	
	/**
	Replaces a key with another provided one, by trying to match the given data with a key
	*/
	public func replaceKey(usingType type: InlineKeyType, data: String, newKey: MarkupInlineKey) -> Bool {
		
		for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var replaced = false
			
			// Iterate through each key in each row for a match
			for (i, key) in newRow.enumerated() {
				if replaced == true { continue }
				
				if key.type == type {
					if key.data == data {
						newRow.remove(at: i)
						newRow.insert(newKey, at: i)
						replaced = true
					}
				}
			}
			
			// If we made a match, switch out the rows and exit
			if replaced == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
			
		}
		
		return false
	}
	
	/**
	Replaces a key with another provided one, by trying to match the keys it has with one that's provided.
	*/
	public func replaceKey(oldKey: MarkupInlineKey, newKey: MarkupInlineKey) -> Bool {
		
		for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var replaced = false
			
			// Iterate through each key in each row for a match
			for (i, key) in newRow.enumerated() {
				if replaced == true { continue }
				
				if key == oldKey {
					newRow.remove(at: i)
					newRow.insert(newKey, at: i)
					replaced = true
				}
			}
			
			// If we made a match, switch out the rows and exit
			if replaced == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
		}
		
		return false
	}
	
	/**
	Tries to find and delete a key, based on a match with one provided.
	*/
	public func deleteKey(key: MarkupInlineKey) -> Bool {
		
		for (rowIndex, row) in keyboard.enumerated() {
			var newRow = row
			var removed = false
			
			// Iterate through each key in each row for a match
			for (i, newKey) in newRow.enumerated() {
				if removed == true { continue }
				
				if key == newKey {
					newRow.remove(at: i)
					removed = true
				}
			}
			
			// If we made a match, switch out the rows and exit
			if removed == true {
				keyboard.remove(at: rowIndex)
				keyboard.insert(newRow, at: rowIndex)
				return true
			}
		}
		
		return false
	}
	
	static public func ==(lhs: MarkupInline, rhs: MarkupInline) -> Bool {
		
		if lhs.keyboard.count != rhs.keyboard.count { return false }
		
		for (i, lhsRow) in lhs.keyboard.enumerated() {
			
			let rhsRow = rhs.keyboard[i]
			if lhsRow.count != rhsRow.count { return false }
			
			for (iKey, lhsKey) in lhsRow.enumerated() {
				
				let rhsKey = rhsRow[iKey]
				if lhsKey != rhsKey { return false }
			}
		}
		
		return true
	}
	
}
