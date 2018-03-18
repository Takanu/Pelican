//
//  Codable+String.swift
//  Pelican
//
//  Created by Takanu Kyriako on 16/03/2018.
//

import Foundation

extension Encodable {
	func encodeToUTF8() throws -> String? {

		var jsonData = Data()
	
		do {
			jsonData = try JSONEncoder().encode(self)
			
		} catch {
			if self is String {
				let result = self as! String
				return result
			}
				
			else if self is Int {
				let result = self as! Int
				return result.description
			}
				
			else if self is Double {
				let result = self as! Double
				return result.description
			}
				
			else if self is Decimal {
				let result = self as! Decimal
				return result.description
			}
			
			
			PLog.error("Serialisation Error - \(error)")
			return nil
		}
	
		return String(data: jsonData, encoding: .utf8)
	}
}

