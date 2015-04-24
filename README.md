<h1> Socializer </h1>
Is as an iOS Twitter feed using Swifter as its engine. 
Tweets are displayed in table view and reloaded with refresh control and when user scrolls to the bottom. Once user taps on the cell another screen opens up with media that is contained in the tweet.
Enjoy it.

To use it in your app you have to copy the files:
TwitterViewController.swift
Parser.swift
NetworkingOperations.swift
MediaViewController.swift 

And change the key and consumer secret in the TweeterManager to your values:
var tm:TweeterManager =  TweeterManager(consumerKey:  "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret:"7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne")


