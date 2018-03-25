//
//  Pelican+Errors.swift
//  Pelican
//
//  Created by Takanu Kyriako on 23/01/2018.
//

import Foundation

/**
Errors relating to Pelican setup.
*/
public enum PError_Codable: String, Error {
	case InlineResultAnyDecodable = "InlineResultAny was unable to be decoded, InlineResultAny is only a wrapper and should not be treated as an entity to encode and decode to."
}

/**
Errors relating to Pelican setup.
*/
public enum TGBotError: String, Error {
	case WorkingDirNotFound = "The working directory couldn't be found."
	case ConfigMissing = "The config file is missing.  Make sure you include a \"config.json\" file in the project bundle that contains your API token."
	case KeyMissing = "The API key hasn't been provided.  Please provide a \"bot_token\" in your bundle's config.json, containing your bot token."
	case EntryMissing = "Pelican hasn't been given an session setup closure.  Please provide one using `sessionSetupAction`."
	case NoPollingInterval = "Pelican hasn't been given a polling interval.  Please set one using `Pelican.pollInterval`."
}

/**
Errors related to request fetching.
*/
public enum TGReqError: String, Error {
	case NoResponse = "The request received no response."
	case UnknownError = "Something happened, and i'm not sure what!"
	case BadResponse = "Telegram responded with \"NOT OKAY\" so we're going to trust that it means business."
	case ResponseNotExtracted = "The request could not be extracted."
}

/**
Errors related to update processing.  Might merge the two?
*/
public enum TGUpdateError: String, Error {
	case BadUpdate = "The message received from Telegram was malformed or unable to be processed by this bot."
}

/**
Motherfucking Vapor.
*/
public enum TGVaporError: String, Error {
	case EngineSucks = "Engine is unable to keep an SSL connection going, please use \"foundation\" instead, under your droplet configuration file."
}
