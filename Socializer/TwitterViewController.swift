//
//  SecondViewController.swift
//  Socializer
//
//  Created by sadmin on 3/10/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import UIKit
//import Darwin



class TweeterManager{
    var tweets : [JMCTweet] = []
    var images :[String: UIImage] = [String: UIImage]()
    var networkingManager:Networking
    var parser:Parser
    
    var swifter: Swifter
    var searchQuery = "tripadvisor"
    var count = 50
    
    var completionHandler:(()->Void)? //updating entire table
    var errorHandler:((error:String)->Void)? // errors
   // var downloadHandler:((path:String, image:UIImage)->Void)?
    var cellUpdater:((messageIds:[UInt64])->Void)?
    var tweetsIds = [UInt64:Bool]()
    
    
    var maxId:UInt64?
    var minId:UInt64?
    
    var authorized = false
    
    
    init(){
        swifter = Swifter(consumerKey: "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret: "7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne", appOnly: true)
        networkingManager = Networking()
        parser = Parser()
        
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
        authenticateApp()
    }
    
    
    //get all
    func getTweetsWithHandler(completionHandler:()->Void, errorHandler:(error:String)->Void, cellHandler:(messagesIds:[UInt64])->Void, upperBond:Bool, lowerBond:Bool ){
        
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
    

    //Keeps track on
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
    
        func getTweetsWithSearchQuery(searchQuery:String, maxId:String?, minId:String?){
            

            self.swifter.getSearchTweetsWithQuery(
                searchQuery, geocode: nil, lang: nil, locale: nil, resultType: nil, count: count, until: nil, sinceID:minId, maxID: maxId, includeEntities: nil, callback: nil, success: { (statuses, searchMetadata) -> Void in
                    
                    if let stats = statuses {
                        
                        self.updateBoundaries(stats)

                        for status in statuses! {
                            
                           var tweet = JMCTweet()
                           tweet.updateWithData(status)
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
        
        
        //get recent tweets
        func authenticateApp(){
            self.swifter.authorizeAppOnlyWithSuccess({ (accessToken, response) -> Void in
                
                self.authorized = true
                }, failure: { (error) -> Void in
                    self.authorized = false
                    println(error)
                    
                    
                    self.tweets.removeAll(keepCapacity: false)
                    
                    var t:JMCTweet = JMCTweet()
                    t.text = error.debugDescription
                    self.tweets.append(t)
                    
                    if let handler = self.completionHandler {
                        handler()
                    }
                    
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


    class ImageCell:BasicCell {
        @IBOutlet weak var imageAttachment: UIImageView!
        

    }


    class BasicCell: UITableViewCell {
        
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet var textView: UITextView!
        
        @IBOutlet weak var dateLabel: UILabel!
        @IBOutlet weak var cellImageView: UIImageView!
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }
        
        required init(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        /// Custom setter so we can initialise the height of the text view
        var textString: String {
            get {
                return textView.text
            }
            set {
                textView.text = newValue
                textViewDidChange(textView)
            }
        }
        
        override func awakeFromNib() {
            super.awakeFromNib()
            
            // Disable scrolling inside the text view so we enlarge to fitted size
            textView.scrollEnabled = false
            textView.delegate = self
            
        }
        
        override func setSelected(selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            
            if selected {
                textView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
        }
    }
    
    extension BasicCell: UITextViewDelegate {
        func textViewDidChange(textView: UITextView!) {
            
            // Only way found to make table view update layout of cell
            // More efficient way?
            if let tableView = tableView {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
    
    
    extension UITableViewCell {
        /// Search up the view hierarchy of the table view cell to find the containing table view
        var tableView: UITableView? {
            get {
                var table: UIView? = superview
                while !(table is UITableView) && table != nil {
                    table = table?.superview
                }
                
                return table as? UITableView
            }
        }
    }
    
    
    class TwitterViewController: UITableViewController {
        
        var tm:TweeterManager =  TweeterManager()

        // var networkingManager = Networking()
        func updateTable()->Void{
            
            //get tweets
            self.tableView.reloadData()
            endRefreshing()
        }
        
        func updateCells(messageIds:[UInt64]?)
        {
            
            //search for messages with id using quadratic function! bad.
            var indexes = [NSIndexPath]()
            if let messages = messageIds  {
                if messages.count == 0 {return}
                if tm.tweets.count == 0 {return}
           
                for i in 0...tm.tweets.count-1 {
                    for j in 0 ... messages.count-1{
                    if tm.tweets[i].id == messages[j] {
                        //assuming this is only one section
                            indexes.append(NSIndexPath(forRow: i, inSection: 0))
                        }
                    }
                }
            }
            
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    // do some task
                    dispatch_async(dispatch_get_main_queue()) {
                        // update some UI
                        self.tableView.reloadRowsAtIndexPaths(indexes, withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
        }
        
        
        func errorHandler(error:String)->Void{
            endRefreshing()
        }
        
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
           
            if(segue.identifier == "showMedia"){
                if let k  = sender as? UITableViewCell
                {
                    var vc = segue.destinationViewController as MediaViewController
                    let indexPath = self.tableView.indexPathForCell(k)
                    let tweet = self.tm.tweets[indexPath!.row]
                    vc.urls = tweet.urls
                    
                    
                }
            }
            if(segue.identifier == "showMedia2"){
                if let k  = sender as? UITableViewCell
                {
                    var vc = segue.destinationViewController as MediaViewController
                    let indexPath = self.tableView.indexPathForCell(k)
                    let tweet = self.tm.tweets[indexPath!.row]
                    tweet.urls?.append(NSURL(string:tweet.messageImageURL!)!)
                    vc.urls = tweet.urls
                    
                    
                }
            }
            
            
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.title = "Twitter"
            self.navigationController?.title = "Twitter"
            self.navigationController?.navigationBar.translucent = false
            
            
            // Do any additional setup after loading the view, typically from a nib.
            self.refreshControl = UIRefreshControl()
            self.refreshControl!.tintColor = UIColor.darkGrayColor()
            self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to Refresh")
            self.refreshControl!.addTarget(self, action: "loadMore", forControlEvents: UIControlEvents.ValueChanged)
            
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 44.0
            tableView.reloadData()

            tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCells, upperBond: false, lowerBond: false)
            
        }
        
        func loadMore(){
            tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCells, upperBond: false, lowerBond: true)
            
        }
        
        func endRefreshing(){
            self.refreshControl!.endRefreshing()
        }
        
        
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            // if self.tm.messages.count > 0 {return 2}
            
            return 1
        }
        
        override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return self.tm.tweets.count
        }
        
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            ///let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "tweetCell") as TweetCell
            let tweet = tm.tweets[indexPath.row]
            if (indexPath.row ==  tm.tweets.count - 1)
            {
                tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCells, upperBond: true, lowerBond: false)
//                println("reload\(indexPath.row)")
//                println("reload\(tm.tweets.count)")
                
            }
            
            
            if let img = tweet.messageImageURL {
                var cell = tableView.dequeueReusableCellWithIdentifier("imageCell") as ImageCell
                cell.imageAttachment.image = tm.images[tweet.messageImageURL!]
                cell.titleLabel.text = tweet.name
                cell.textView.text = tweet.text
                cell.textView.userInteractionEnabled = false
                cell.dateLabel.text = tweet.date
                if let t = tweet.profileImageURL {
                    
                    cell.cellImageView.image = tm.images[tweet.profileImageURL!]
                    
                }
                
                if let attachments = tweet.urls
                {
                    
                    if attachments.count > 0 {
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cell.userInteractionEnabled = true
                        cell.selectionStyle = UITableViewCellSelectionStyle.Default
                        
                    }
                    else{
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.userInteractionEnabled = false
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                    }
                }
                else{
                    cell.accessoryType = UITableViewCellAccessoryType.None
                    cell.userInteractionEnabled = false
                    cell.selectionStyle = UITableViewCellSelectionStyle.None
                }
                 return cell
            }
            else{
                var cell = tableView.dequeueReusableCellWithIdentifier("basicCell") as BasicCell
                if let t = tweet.profileImageURL {
                    
                    cell.cellImageView.image = tm.images[tweet.profileImageURL!]
                    
                }
                
                if let attachments = tweet.urls
                {
                    cell.titleLabel.text = tweet.name
                    cell.textView.text = tweet.text
                    cell.textView.userInteractionEnabled = false
                    cell.dateLabel.text = tweet.date
                    
                    if attachments.count > 0 {
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        cell.userInteractionEnabled = true
                        cell.selectionStyle = UITableViewCellSelectionStyle.Default
                        
                    }
                    else{
                        cell.accessoryType = UITableViewCellAccessoryType.None
                        cell.userInteractionEnabled = false
                        cell.selectionStyle = UITableViewCellSelectionStyle.None
                    }
                }
                else{
                    cell.accessoryType = UITableViewCellAccessoryType.None
                    cell.userInteractionEnabled = false
                    cell.selectionStyle = UITableViewCellSelectionStyle.None
                }
                 return cell
                
                
            }
        }
}

