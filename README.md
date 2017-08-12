# Pelican 0.7 Alpha
## (Vapor 2) Telegram API Wrapper for Swift x Vapor.

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

- Modular Session System for generating active objects to contain updates within a chat-based, user-based or custom update scope.
- Modular Routing System for matching incoming update contents to bot or session functionality.
- In-Built Moderator, Flood, Timeout and Queue systems
- Inline message containers ("Prompts") for inline message response and update management
- A bunch of other cool stuff!

The code has extensive documentation to help you use it, and I will include up-to-date tests and demo code soon.  If you have any questions, feel free to message me on GitHub or on Telegram at t.me/takanu.
