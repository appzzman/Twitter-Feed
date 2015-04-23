//
//  TweeterManager.swift
//  Socializer
//
//  Created by Janusz Chudzynski on 4/22/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//
import UIKit
import Foundation

class TweeterManager{
    var tweets : [JMCTweet] = []
    var images :[String: UIImage] = [String: UIImage]()
    var networkingManager:Networking
    var parser:Parser
    var swifter: Swifter
    
    var searchQuery = "tripadvisor"
    var count = 100
    var queringInterval = 2
    
    var completionHandler:(()->Void)? //updating entire table
    var errorHandler:((error:String)->Void)? // errors
    var cellUpdater:((messageIds:[UInt64]?)->Void)?//updates single cell identified by ID
    var tweetsIds = [UInt64:Bool]()
    var lastRequest:NSDate?
    
    
    dynamic var authorized:Bool = false
    
    //min and max boundaries of message ids
    var maxId:UInt64?
    var minId:UInt64?
    
    //Default initializer
    init(consumerKey:String, consumerSecret:String){
        
        swifter = Swifter(consumerKey: consumerKey, consumerSecret:consumerSecret, appOnly: true)
        networkingManager = Networking()
        parser = Parser()
      //  authenticateApp()
        
        /*Called when parser finishes parsing the message */
        parser.urlHandler = { (messageId:UInt64, urls:[NSURL]? )->Void in
            
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                // do some task
                //  let ids = self.tweets.map({$0.id})
                if let handler = self.cellUpdater {
                    for tweet in self.tweets {
                        if tweet.id! == messageId {
                            tweet.urls = urls
                            if let updater = self.cellUpdater{
                                updater(messageIds: [tweet.id!])
                            }
                        }
                    }
                }
            }
        }
        
        self.networkingManager.downloadHandler = {(path:String, img:UIImage?, keyPath:String)->Void in
            
            self.images[path] = img
            if let handler = self.cellUpdater {
                var found = [UInt64]()
                for tweet in self.tweets {
                    if tweet.valueForKey(keyPath) as? String == path {
                        found.append(tweet.id!)
                        
                        break;
                    }
                }
                
                handler(messageIds: found)
                
            }
        }

    }
    
    
    //get all tweets
    func getTweetsWithHandler(completionHandler:()->Void, errorHandler:(error:String)->Void, cellHandler:(messagesIds:[UInt64]?)->Void, upperBond:Bool, lowerBond:Bool ){
        
        //update the handlers
        self.completionHandler = completionHandler // entire table
        self.errorHandler = errorHandler //error handler
        self.cellUpdater = cellHandler
        
        
        if (upperBond == true) {
            
            if let mid = self.minId {
                self.getTweetsWithSearchQuery(self.searchQuery,maxId: String(mid-1), minId: nil)
            }
            else{
                self.getTweetsWithSearchQuery(self.searchQuery,maxId: nil,minId: nil)
            }
        }
        else if lowerBond == true {
            if let xId = self.maxId
            {
                self.getTweetsWithSearchQuery(self.searchQuery , maxId: nil, minId: String(xId))
            }
            else{
                self.getTweetsWithSearchQuery(self.searchQuery,maxId: nil,minId: nil)
            }
            
        }
        else{
            self.getTweetsWithSearchQuery(self.searchQuery,maxId: nil,minId: nil)
        }
    }
    
    
    //Keeps track of boundaries
    func updateBoundaries(statuses:[JSONValue]){
        
        
        for status in statuses {
            var tweet = JMCTweet()
            
            if let id = status["id_str"].string {
                let longid =  strtoull(id, nil, 10)
                if self.minId  == nil {
                    self.minId = longid
                }
                if self.maxId  == nil {
                    self.maxId = longid
                }
                
                if longid > self.maxId
                {
                    self.maxId = longid
                }
                
                if longid < self.minId
                {
                    self.minId = longid
                }
            }
        }
    }
    
    
    //parse messages
    func parseMessages(messages:[JSONValue])
    {
        for message in messages {
            
            var tweet = JMCTweet()
            tweet.updateWithData(message)
            if (self.tweetsIds [tweet.id!] == nil)  {
                if let profile =  tweet.profileImageURL {
                    var image = self.networkingManager.getImage(profile,keyPath:"profileImage")
                    if let img = image {
                        tweet.profileImage = img
                        self.images[tweet.profileImageURL!] = img
                        //reload cell
                    }
                }
                
                if let media_url = tweet.messageImageURL
                {
                    var image = self.networkingManager.getImage(media_url, keyPath:"messageImage")
                    if let img = image {
                        tweet.messageImage = img
                        self.images[tweet.messageImageURL!] = img
                    }
                }
                
                if tweet.id != nil && tweet.text != nil {
                    self.parser.parseMessage(tweet.text!, messageId: tweet.id!)
                }
                
                self.tweets.append(tweet)
                self.tweetsIds[tweet.id!] = true
                
            }
        }
    }
    
    
    //gets tweets 
    func getTweetsWithSearchQuery(searchQuery:String, maxId:String?, minId:String?){
        
        if let request = lastRequest {
            let date = NSDate()
            if Int(date.timeIntervalSinceDate(request)) < Int( self.queringInterval)
            {
                
            }
            lastRequest = date
        }
        
        
        self.swifter.getSearchTweetsWithQuery(
            searchQuery, geocode: nil, lang: nil, locale: nil, resultType: nil, count: count, until: nil, sinceID:minId, maxID: maxId, includeEntities: nil, callback: nil, success: { (statuses, searchMetadata) -> Void in
                
                if let stats = statuses {
                    
                    self.updateBoundaries(stats)
                    self.parseMessages(stats)
                    
                    //reload table
                    if let handler = self.completionHandler {
                        handler()
                    }
                }
                
                
            }
            , failure: { (error) -> Void in
                println("Error:\(error)")
                self.tweets.removeAll(keepCapacity: false)
                var json = JSONValue(error.debugDescription)
                
                if let handler = self.completionHandler {
                    handler()
                }
        })
    }
    
    
    //authenticate app
 func authenticateApp(completionHandler:()->Void, errorHandler:(error:String)->Void){
        self.swifter.authorizeAppOnlyWithSuccess({ (accessToken, response) -> Void in
            self.authorized = true
            }, failure: { (error) -> Void in
                println(error)
        })
    }
}


class JMCTweet : NSObject{
    var text:String?
    var name:String?
    var id:UInt64?
    var stringId:String?
    var profileImageURL:String?
    var profileImage:UIImage?
    var urls:[NSURL]?
    var messageImageURL:String?
    var messageImage:UIImage?
    var mentions:[String]?
    var date:String?
    
    func updateWithData(data:JSONValue){
        
        if  let id = data["id_str"].string
        {
            let longid =  strtoull(id, nil, 10)
            self.id = longid
            self.stringId = data["id_str"].string
        }
        
        var url =  data["entities"]["media_url"]
        if let medias = data["entities"]["media"].array
        {
            for i in 0...medias.count-1
            {
                if let url = medias[i]["media_url"].string {
                    self.messageImageURL = url
                }
            }
        }
        
        self.name = data["user"]["name"].string
        self.profileImageURL = data["user"]["profile_image_url_https"].string
        var indate = data["created_at"].string!
        self.date = Parser.parseTwitterDate(indate, outputDateFormat: nil)
        
        
        
        //parse message
        if let txt = data["text"].string {
            self.text = txt
        }
    }
}
