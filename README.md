# Pelican Alpha
## (Vapor 1.5x) Telegram API Wrapper for Swift x Vapor.

Hi 2-3 people that somehow both like Telegram, Swift and Vapor!   This is a Provider that gives your Droplet a complete solution for creating and managing Telegram bots.  **It's still a little rough and not everything has been finished, so be careful**

If you’ve never heard of [Telegram](telegram.org) it’s an awesome non-profit, secure messaging service that offers so many cool features that it’s kind of hard to list them all but i’ll try:


* Open Stickers Platform 
* 5000 Member Groups 
* Access Chats From Any Device 
* 1.5GB File Transfer 
* HTML5 Game Platform 
* Apps For Literally Everything (Tablets, Desktop, Smartwatches)
* The fact that you can talk to someone without giving out your phone number through the magic of usernames like [t.me/takanu](t.me/takanu) (hey thats me).
* Channels where you can publish content to an unlimited number of followers

Where bots are concerned though, Telegram offers an open and free API system where you can make bots for all kinds of tasks, from helping schedule channel posts to operating your own online HTML5 games that are playable inside the app (and since you’re using Vapor, you could conceivably manage everything in one app).

So, what does Pelican do currently?

**Support for most Bot Types/Methods (Is this a feature?)**

Nearly everything is represented, the only thing currently missing are most Inline Types.  Databasing should also work using most database types.

**User Session System**

This handles the act of creating, updating and destroying individual sessions with any number of users.  The criteria for creating a session and the scope of users that can use it are customisable, and it includes Whitelists, Blacklists, Timeouts, Flood Limits and a bunch of other neat things.  Sessions can also be databased for later use if the user wants to stop and you want to free up active sessions.

Sessions in a later update will also conform to Model so they can be databased, if you want to save bot states and free up live sessions.

**State and Timer Systems**

You can create function states for any kind of response that Telegram receive to filter and handle incoming updates.  Additionally you can schedule method calls and closures to be executed at a later time using the action system.

**Asynchronous File Uploads and File Cache System**

Any time you attempt to upload a file from the server, it will always upload in separate threads and pause the session or sessions that are waiting for those files to come through.  Once a file is uploaded, it will save the File ID internally and automatically use that ID instead of re-uploading when the file is referenced again later.

(not all link and upload types are currently supported, and this needs a little more work)

**Prompts**

Prompts provide a convenient way to encapsulate behaviour for an inline keyboard message.  Quickly create one-time options, provide transforming bot controls or call a user vote using simple initialisers and the user session system will handle the rest.

**Maintenance Bot Features (coming soon)**

Soon, you will be able to provide Pelican with a secondary bot token to be used to monitor bot activity and check things like active sessions and general activity, as well as perform basic moderation tasks like blacklisting or whitelisting users or chats and receive alerts when abnormal behaviour is detected or if your bot is on fire.

**Server Monitoring (coming soon)**

Even if you don’t want to make a Telegram bot at all, this provider in the future could still be used as a way to monitor how your servers are doing through Telegram.  Simply hook it up to a bot and you can get stats, perform basic commands and be notified if your server is on fire.


### Limitations
When finished it'll have just one:

- No Webhook Support
Sorry, but maybe later…

Special thanks to Marvin, my other web developer friends and the Vapor Slack group for putting up with my dumb questions over the last few months.
