//
//  MessageType.swift
//  Pelican
//
//  Created by Ido Constantine on 21/12/2017.
//

import Foundation

/**
Defines a message type, and in most cases also contains the contents of that message.
*/
public enum MessageType {
	
	case audio(Audio)
	case contact(Contact)
	case document(Document)
	case game(Game)
	case photo([Photo])
	case location(Location)
	case sticker(Sticker)
	case venue(Venue)
	case video(Video)
	case videoNote(VideoNote)
	case voice(Voice)
	case text
	
	/// Returns the name of the type as a string.
	func name() -> String {
		switch self {
		case .audio(_):
			return "audio"
		case .contact(_):
			return "contact"
		case .document(_):
			return "document"
		case .game(_):
			return "game"
		case .photo(_):
			return "photo"
		case .location(_):
			return "location"
		case .sticker(_):
			return "sticker"
		case .venue(_):
			return "venue"
		case .video(_):
			return "video"
		case .videoNote(_):
			return "video_note"
		case .voice(_):
			return "voice"
		case .text:
			return "text"
		}
	}
}
