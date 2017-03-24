//
//  InlineCachedTypes.swift
//  beach_arcade
//
//  Created by Takanu Kyriako on 18/02/2017.
//
//

import Foundation
import Swift

/*

// An extended class/protocol thing for items that can be considered as cached (stored on Telegram's servers) or not (stored as a URL of the file).
protocol InlineResultCached: InlineResult {
    var isCached: Bool { get } // Determines whether or not the object is cached.  Set internally.
    var fileLink: String { get set } // Depending on whether it's a cached result or not, either the ID of the file or the URL.
}

// makeNode() currently makes no effort to divide content based on whether it's cached or not.
// Use getQuery() instead.

/* Represents either a link to a MP3 audio file stored on the Telegram servers, or an external URL link to one. */
struct InlineResultAudio: NodeConvertible, JSONConvertible, InlineResultCached {
    var type: String = "audio"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent?
    
    var isCached: Bool // Whether the given audio result is stored on Telegram's servers or not.
    var fileLink: String // Identifier/URL depending on the above.
    var caption: String? // Caption, 0-200 characters.

}

/* Represents either a link to a file stored on the Telegram servers, or an external URL link to one.  If sent using an external link, only .PDF and .ZIP files are supported. */
struct InlineResultDocumentCached: NodeConvertible, JSONConvertible, InlineResultCached {
    var type: String = "document"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent?
    
    var isCached: Bool // Whether the given audio result is stored on Telegram's servers or not.
    var fileLink: String // Identifier/URL depending on the above.
    var title: String // Title.
    var caption: String? // Caption, 0-200 characters.
    var description: String? // Short description of the result.

}

/* Represents either a link to an animated GIF stored on the Telegram servers, or an external URL link to one. */
struct InlineResultGIFCached: InlineResultCached {
    var type: String = "gif"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool // Whether the given audio result is stored on Telegram's servers or not.
    var fileLink: String // Identifier/URL depending on the above.
    var title: String? // Title.
    var caption: String? // Caption, 0-200 characters.

}


/* Represents either a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers, or an external URL link to one. */
struct InlineResultMpeg4GIFCached: InlineResultCached {
    var type: String = "mpeg4_gif"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool // Whether the given audio result is stored on Telegram's servers or not.
    var fileLink: String // Identifier/URL depending on the above.
    var title: String? // Title.
    var caption: String? // Caption, 0-200 characters.
    
    
    var thumb: InlineThumbnail

}

/* Represents either a link to a photo stored on the Telegram servers, or an external URL link to one. */
struct InlineResultPhotoCached: InlineResultCached {
    var type: String = "photo"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
    var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
    
    var title: String? // Title.
    var caption: String? // Caption, 0-200 characters.
    var description: String? // Short description of the result.
    var thumb: InlineThumbnail
}


/* Represents a link to a sticker stored on the Telegram servers.  Stickers can only ever be cached. */
struct InlineResultStickerCached: InlineResultCached {
    var type: String = "sticker"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool = true // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
    var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
}

/* Represents either a link to a video stored on the Telegram servers, or an external URL link to a page containing an embedded video player or video file. */
struct InlineResultVideoCached: InlineResultCached {
    var type: String = "video"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
    var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
    
    var title: String? // Title.
    var caption: String? // Caption, 0-200 characters.
    
    var mimeType: String // Mime type of the content of the file, either “text/html" or "video/mp4"
    var thumb: InlineThumbnail // URL of the thumbbail for the result.
    var duration: Int? // Video duration in seconds.
}

/* Represents either a link to a voice message (in an .ogg container encoded with OPUS) stored on the Telegram servers, or an external URL link to one. */
struct InlineResultVoiceCached: InlineResultCached {
    var type: String = "voice"
    var id: String
    var replyMarkup: InlineKeyboardMarkup?
    var inputMessageContent: InputMessageContent
    
    var isCached: Bool // Determines whether the given audio result is cached (stored on Telegram's servers) or not.
    var fileLink: String // Either a valid identifier for the audio file if cached, or a URL if not.
    
    var title: String // Title.
    var caption: String? // Caption, 0-200 characters.
    var duration: Int? // Audio duration in seconds.
}
 
 */
