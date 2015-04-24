<h1> Twitter Feed </h1>
Is as an iOS Twitter feed using Swifter as its engine. 
Tweets are displayed in table view and reloaded with refresh control and when user scrolls to the bottom. Once user taps on the cell another screen opens up with media that is contained in the tweet.


To use it in your app you have to copy the files:
<ul>
<li>TwitterViewController.swift</li>
<li>Parser.swift</li>
<li>NetworkingOperations.swift</li>
<li>MediaViewController.swift </li>
</ul>

And change the key and consumer secret in the TweeterViewController to your values:
```
var tm:TweeterManager =  TweeterManager(consumerKey:  "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret:"7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne")
```
And change the query to look for to your desire one:
```
tm.searchQuery = "TwitterAPI"
```
Enjoy it. Let me know if you have any questions,
Janusz
