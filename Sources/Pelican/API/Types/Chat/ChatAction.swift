//
//  ChatAction.swift
//  Pelican
//
//  Created by Takanu Kyriako on 06/03/2018.
//

import Foundation

/**
Defines a type of chat action you can use via `setChatAction`, if an action your bot is taking will
take some time but you wish to inform the people using it that the bot is still processing their request.
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
