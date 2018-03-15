//
//  ChatAction.swift
//  Pelican
//
//  Created by Ido Constantine on 06/03/2018.
//

import Foundation

/**
Defines the kind of action you wish a chat action to specify.  (This description sucks).

- note: Should be moved to Types+Standard
*/
public enum ChatAction: String {
	case typing = "typing"
	case photo = "upload_photo"
	case uploadVideo = "upload_video"
	case recordVideo = "record_video"
	case uploadAudio = "upload_audio"
	case recordAudio = "record_audio"
	case document = "upload_document"
	case location = "find_location"
}
