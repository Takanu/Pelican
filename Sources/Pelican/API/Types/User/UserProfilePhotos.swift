//
//  UserProfilePhotos.swift
//  Pelican
//
//  Created by Takanu Kyriako on 31/08/2017.
//

import Foundation



final public class UserProfilePhotos: Codable {
	
	/// The total number of photos the user has on their profile.
	public var totalCount: Int
	
	/// The requested photos for the user (up to 4 sizes per unique photo).
	public var photos: [[Photo]] = []
	
	/// Coding keys to map values when Encoding and Decoding.
	enum CodingKeys: String, CodingKey {
		case totalCount = "total_count"
		case photos
	}
	
	public init(photoSets: [Photo]...) {
		for photo in photoSets {
			photos.append(photo)
		}
		totalCount = photos.count
	}
}
