//
//  InlineResultType.swift
//  Pelican
//
//  Created by Takanu Kyriako on 22/01/2018.
//

import Foundation

public enum InlineResultType: String, Codable {
	case article, audio, contact, document, game, gif, location
	case mpeg4Gif = "mpeg4_gif"
	case photo, sticker, venue, video, voice
	
	var metatype: InlineResult.Type {
		switch self {
		case .article:
			return InlineResultArticle.self
		case .audio:
			return InlineResultAudio.self
		case .contact:
			return InlineResultContact.self
		case .document:
			return InlineResultDocument.self
		case .game:
			return InlineResultGame.self
		case .gif:
			return InlineResultGIF.self
		case .location:
			return InlineResultLocation.self
		case .mpeg4Gif:
			return InlineResultMpeg4GIF.self
		case .photo:
			return InlineResultPhoto.self
		case .sticker:
			return InlineResultSticker.self
		case .venue:
			return InlineResultVenue.self
		case .video:
			return InlineResultVideo.self
		case .voice:
			return InlineResultVoice.self
		}
	}
}
