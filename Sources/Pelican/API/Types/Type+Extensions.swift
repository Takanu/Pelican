//
//  Type+Extensions.swift
//  Pelican
//
//  Created by Ido Constantine on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

/*
An extension used to switch from snake to camel case and back again
*/
extension String {
	
	/**
	Checks that the given URL for MessageFile types is either a valid internal or remote source.
	*/
	func checkURLValidity(acceptedExtensions: [String]) -> Bool {
		
		// Check that the file has a valid file-extension.
		if acceptedExtensions.count > 0 {
			if self.components(separatedBy: ".").last == nil { return false }
		
		
			let ext = self.components(separatedBy: ".").last!
			if acceptedExtensions.contains(ext) == false { return false }
		
			return true
		}
		
		// Add checks for remote/internal paths and path consistency.
		return true
	}
	
	/**
	Converts a string that has snake case formatting to a camel case format.
	*/
	var snakeToCamelCase: String {
		
		let items = self.components(separatedBy: "_")
		var camelCase = ""
		
		items.enumerated().forEach {
			camelCase += 0 == $0 ? $1 : $1.capitalized
		}
		
		return camelCase
	}
	
	/**
	Converts a string that has camel case formatting to a snake case format.
	*/
	var camelToSnakeCase: String {
		
		// Check that we have characters...
		guard self.characters.count > 0 else { return self }
		
		var newString: String = ""
		
		// Break up the string into only "Unicode Scalars", which boils it down to a UTF-32 code.
		// This allows us to check if the identifier belongs in the "uppercase letter" set.
		let first = self.unicodeScalars.first!
		newString.append(Character(first))
		
		for scalar in self.unicodeScalars.dropFirst() {
			
			// If the unicode scalar contains an upper case letter, add an underscore and lowercase the letter.
			if CharacterSet.uppercaseLetters.contains(scalar) {
				let character = Character(scalar)
				newString.append("_")
				newString += String(character).lowercased()
			}
				
				// Otherwise append it to the new string.
			else {
				let character = Character(scalar)
				newString.append(character)
			}
		}
		
		return newString
	}
}


extension Row {
	
	/**
	Strips row data of any entries that have a value of "null", including any nested data.
	Useful for constructing queries and requests where null values are not compatible.
	*/
	mutating func removeNullEntries() throws {
		
		if self.object != nil {
			for row in self.object! {
				
				if row.value.isNull == true {
					self.removeKey(row.key)
				}
					
				else if row.value.object != nil {
					var newRow = row.value
					try newRow.removeNullEntries()
					self.removeKey(row.key)
					try self.set(row.key, newRow)
				}
			}
		}
	}
}
