//
//  UserProfilePhotos.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation
import Vapor
import FluentProvider

final public class UserProfilePhotos: Model {
	public var storage = Storage()
	public var totalCount: Int
	public var photos: [[PhotoSize]] = []
	
	public init(photoSets: [PhotoSize]...) {
		for photo in photoSets {
			photos.append(photo)
		}
		totalCount = photos.count
	}
	
	
	// NodeRepresentable conforming methods
	public required init(row: Row) throws {
		totalCount = try row.get("total_count")
		photos = try row.get("photos")
	}
	
	public func makeRow() throws -> Row {
		var row = Row()
		try row.set("total_count", totalCount)
		try row.set("photos", photos)
		
		return row
	}
}
