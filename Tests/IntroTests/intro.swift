/// Import Vapor and get a droplet
import Vapor
import Pelican
import Foundation


// Do your setup here, this is when the session gets created and any states for
// receiving message types should be setup.
func setupBot(session: TelegramBotSession) {
    session.messageState = startBot
}


// What happens when a session hits a flood warning.
func floodWarning(session: TelegramBotSession) {
    _ = session.send(message: "Hey, easy on the sending, or I might have to blacklist ya!", markup: nil)
}


// What the user or chat receives if they try to interact with the bot but no more sessions can be created.
func maxSessionsWarning(bot: Pelican, chat: Chat) {
    _ = bot.sendMessage(chatID: chat.tgID, text: "Sorry, the bot is a bit busy right now.  Try again later!", replyMarkup: nil)
}


// What happens when due to a timeout, the session is dropped from the active list.
func sessionEnd(session: TelegramBotSession) {
    let keyboard = MarkupKeyboardRemove(isSelective: false)
    _ = session.send(message: "You haven't responded in a while, you okay?\n\nI'm going to do something else now, message me back using /start when you wanna play again.", markup: keyboard)
}



// The state added by setupBot to start receiving an initial start message.
func startBot(msg: Message, session: TelegramBotSession) {
    if msg.text != nil && msg.from != nil {
        let text = msg.text!
        
        switch text {
        case "/start":
            _ = session.send(message: "Hey, this works!")
            
        default:
            _ = session.send(message: "Hey, this also works!")
        }
    }
}



// Make sure you set up Pelican manually so you can assign it variables.
let drop = Droplet()
let pelican = try Pelican(config: drop.config)
drop.addProvider(pelican)

// These two variables are required for the bot to start.
pelican.sessionSetupAction = setupBot
pelican.setPoll(interval: 1)

// This defines what message types your bot can receive.
pelican.allowedUpdates = [.message, .callback_query, .inline_query, .chosen_inline_result]

// Lets you define a custom object that will be attached to every session as .data.
//pelican.setCustomData(YourClass())


// Session Setup
pelican.maxSessions = 30                               // The number of sessions the bot can support before it will stop creating them
pelican.maxSessionsAction = maxSessionsWarning         // The action that takes place when someone tries to make a session but the limit has been reached
pelican.defaultMaxSessionTime = 1000                   // The length of time a session lasts for before being dropped.


// Flood Limit Setup
pelican.floodLimit = FloodLimit(limit: 20, range: 30, breachLimit: 2, breachReset: 180)
pelican.floodLimitWarning = floodWarning
pelican.chatWhitelist.append(Chat(id: 000000000000, type: ""))  // Lets you add a chat ID to the whitelist.  If the whitelist is in use then only chats on it can use the bot.

// Response Setup
pelican.responseLimit = 1       // Defines how many messages the bot will attempt to
                                // respond to in any given poll update, before ignoring the rest.  Helps with duplicate
                                // messages or people spamming requests.


// START IT UP!
drop.run()





