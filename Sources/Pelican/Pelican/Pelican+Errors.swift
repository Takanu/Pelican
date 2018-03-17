//
//  Pelican+Errors.swift
//  Pelican
//
//  Created by Ido Constantine on 23/01/2018.
//

import Foundation

/**
Errors relating to Pelican setup.
*/
enum PError_Codable: String, Error {
	case InlineResultAnyDecodable = "InlineResultAny was unable to be decoded, InlineResultAny is only a wrapper and should not be treated as an entity to encode and decode to."
}

/**
Errors relating to Pelican setup.
*/
enum TGBotError: String, Error {
	case WorkingDirNotFound "The working directory couldn't be found."
	case ConfigMissing = "The config file is missing.  Make sure you include a \"config.json\" file in the project directory that contains your API token."
	case KeyMissing = "The API key hasn't been provided.  Please provide a \"token\" for Config/pelican.json, containing your bot token."
	case EntryMissing = "Pelican hasn't been given an session setup closure.  Please provide one using `sessionSetupAction`."
}

/**
Errors related to request fetching.
*/
enum TGReqError: String, Error {
	case NoResponse = "The request received no response."
	case UnknownError = "Something happened, and i'm not sure what!"
	case BadResponse = "Telegram responded with \"NOT OKAY\" so we're going to trust that it means business."
	case ResponseNotExtracted = "The request could not be extracted."
}

/**
Errors related to update processing.  Might merge the two?
*/
enum TGUpdateError: String, Error {
	case BadUpdate = "The message received from Telegram was malformed or unable to be processed by this bot."
}

/**
Motherfucking Vapor.
*/
enum TGVaporError: String, Error {
	case EngineSucks = "Engine is unable to keep an SSL connection going, please use \"foundation\" instead, under your droplet configuration file."
}
