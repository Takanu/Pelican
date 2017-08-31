//
//  FileLink.swift
//  Pelican
//
//  Created by Takanu Kyriako on 21/08/2017.
//

import Foundation
import Vapor


/**
Defines a link to a file, either locally or remotely stored.  Includes all paramaters needed for the file type.
*/
public protocol File {
	
	var link: FileLink { get set }
	
	func getParameters() -> [String:NodeConvertible]
	
}
