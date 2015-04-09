//
//  SecondViewController.swift
//  Socializer
//
//  Created by sadmin on 3/10/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import UIKit

class Parser{
    let operationQueue:NSOperationQueue = NSOperationQueue() // main operation queue
    var urlHandler:((messageId:UInt64, urls:[NSURL]? )->Void)?//caled when download is completed

    init(){
        
        
    }
    
    func parseMessage(message:String, messageId:UInt64){
        let operation = MessageParser(messageId: messageId, message: message)
        self.operationQueue.addOperation(operation)
        operation.completionBlock = {
            if let handler = self.urlHandler
            {
                handler(messageId: operation.messageId, urls: operation.urls)
            }
        }
    }
    
    
    class func parseStringForURLS(str:String)->[NSURL]?{
        
        
        //        var str = "Pascal Hiel |Security|iBeacon|DDIHi Jackie, You might want to take a look at Kontakt.io's cloudbeacon. [http://kontakt.io/introducing-kontakt-io-cloud-beacon/|leo://plh/http%3A*3*3kontakt%2Eio*3introducing-kontakt-io-cloud-beacon*3/JJkQ?_t=tracking_disc] show less"
        
        var detectorError:NSError?;
        let detector:NSDataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue,error:&detectorError)!
        
        if let error = detectorError
        {
            println(error.debugDescription)
            return nil
        }
        
        var rawMatches:NSArray = detector.matchesInString(str, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
        var matches = [NSURL]()
        for match in rawMatches {
            if let url = match.URL {
                matches.append(url!)
            }
        }
        
        
        return matches
    }
    
    class func parseStringForRegex(str:String)->[NSURL]?{
        
        
        //        var str = "Pascal Hiel |Security|iBeacon|DDIHi Jackie, You might want to take a look at Kontakt.io's cloudbeacon. [http://kontakt.io/introducing-kontakt-io-cloud-beacon/|leo://plh/http%3A*3*3kontakt%2Eio*3introducing-kontakt-io-cloud-beacon*3/JJkQ?_t=tracking_disc] show less"
        
        var detectorError:NSError?;
        let detector:NSDataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue,error:&detectorError)!
        
        if let error = detectorError
        {
            println(error.debugDescription)
            return nil
        }
        
        var rawMatches:NSArray = detector.matchesInString(str, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
        var matches = [NSURL]()
        for match in rawMatches {
            if let url = match.URL {
                matches.append(url!)
            }
        }
        
        
        return matches
    }
    
    
}

//NSOperation for downloading messages
class ImageDownloader: NSOperation {
    let urlString: String
    let filePath:String
    var image:UIImage?
    
    init(urlString: String, filePath:String) {
        self.urlString = urlString
        self.filePath = filePath
    }
    
    override func main() {
        
        if self.cancelled {
            return
        }
        if let urlAddres = NSURL(string: urlString)
        {
            let imageData = NSData(contentsOfURL:urlAddres)
            if(imageData?.length>0){
                //save it to the drive
                let fileManager = NSFileManager.defaultManager()
                if let data = imageData {
                    data.writeToFile(self.filePath, atomically: true)
                    self.image = UIImage(data: data)
                    
                }
            }
            
        }
        if self.cancelled {
            return
        }
        
    }
}

//NSOperation for parsing messages
class MessageParser: NSOperation {
    let messageId: UInt64
    let messageText:String
    var urls:[NSURL]?
    var userIds:[String]?

    init(messageId: UInt64, message:String) {
        self.messageId = messageId
        self.messageText = message
    }
    
    override func main() {
        
        if self.cancelled {
            return
        }
            self.urls = Parser.parseStringForURLS(self.messageText)
        
        
        
        if self.cancelled {
            return
        }
        
    }
}



class Networking{
    
    
    var currentDownloads :[String:NSOperation] = [String:NSOperation]()
    var downloadHandler:((url:String, image:UIImage? )->Void)?//caled when download is completed
    let operationQueue:NSOperationQueue = NSOperationQueue() // main operation queue
    
    func downloadImageForIndexPath(path:String, url:String){
        if let operation = currentDownloads[path] {
            //do nothing and relax. You are downloading the file right now.
            println("dowloading right now")
            
        }
        else{
            
            let operation = ImageDownloader(urlString: url,filePath:path)
            operation.completionBlock = {
                println("Completed")
                self.currentDownloads.removeValueForKey(path)
                if let handler = self.downloadHandler {
                   handler(url: url, image:operation.image)
                    
                }
            }
            
            currentDownloads[path] = operation
            self.operationQueue.addOperation(operation)
            
        }
    }
    
    
    func getImage(url:String)->UIImage?
    {
        
        let fileManager = NSFileManager.defaultManager()
        var path: String = getPath(url)
        
        if(fileManager.fileExistsAtPath(path))
        {
            return UIImage(contentsOfFile: path)
        }
        else{
            downloadImageForIndexPath(path,url:url)
            return nil;
        }
        
    }
    
    func doesItExist(url:String)->Bool{
        let fileManager = NSFileManager.defaultManager()
        var path: String = getPath(url)
        
        if(fileManager.fileExistsAtPath(path))
        {
            return false;
        }
        else{
            return true;
        }
        
    }
    
    
    func getPath(url:String)->String{
        let tempDirectoryTemplate = NSTemporaryDirectory()
        return tempDirectoryTemplate.stringByAppendingPathComponent("\(url.hash)")
        
    }
}




class TweeterManager{
    var tweets : [JMCTweet] = []
    var images :[String: UIImage] = [String: UIImage]()
    var networkingManager:Networking
    var parser:Parser
    
    var swifter: Swifter
    var searchQuery = "twitterAPI"
    var count = 50
    
    var completionHandler:(()->Void)? //updating entire table
    var errorHandler:((error:String)->Void)? // errors
    var downloadHandler:((path:String, image:UIImage)->Void)?
    var cellHandler:((path:String, image:UIImage)->Void)?
    
    var maxId:UInt64?
    var minId:UInt64?
    
    var authorized = false
    
    
    init(){
        swifter = Swifter(consumerKey: "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret: "7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne", appOnly: true)
        networkingManager = Networking()
        parser = Parser()
 
        self.networkingManager.downloadHandler = {(path:String, img:UIImage?)->Void in
            println("Updated Image")
            self.images[path] = img
            if let handler = self.cellHandler {
                handler(path: path, image:img!)
            }
        }
        authenticateApp()
    }
    
    
    //get all
    func getTweetsWithHandler(completionHandler:()->Void, errorHandler:(error:String)->Void, cellHandler:(path:String, image:UIImage?)->Void, upperBond:Bool, lowerBond:Bool ){
        
        
        self.completionHandler = completionHandler // entire table
        self.errorHandler = errorHandler //error handler
        self.cellHandler = cellHandler //
        networkingManager.downloadHandler = cellHandler

        
        if (upperBond == true) {
            if let mid = self.maxId {
                self.getTweetsWithSearchQuery(self.searchQuery,maxId: String(mid), minId: nil)
            }
            else{
                self.getTweetsWithSearchQuery(self.searchQuery,maxId: nil,minId: nil)
            }
        }
        else if lowerBond == true {
            if let xId = self.minId
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
    
    func updateBoundaries(statuses:[JSONValue], min:UInt64?, max:UInt64?){
        var tempMin: UInt64? = min
        var tempMax: UInt64? = max
        for status in statuses {
            
            var tweet = JMCTweet()
            
            if let id = status["id_str"].string {
               
                
                if tweet.id > tempMax
                {
                    tempMax = tweet.id!
                    
                }
                
                if tweet.id < tempMin
                {
                    tempMin = tweet.id!
                }
            }
            
            self.minId = tempMin
            self.maxId = tempMax
            
        }
    }
    
        func getTweetsWithSearchQuery(searchQuery:String, maxId:String?, minId:String?){
            
            
            self.swifter.getSearchTweetsWithQuery(
                searchQuery, geocode: nil, lang: nil, locale: nil, resultType: "recent", count: nil, until: nil, sinceID:minId, maxID: maxId, includeEntities: nil, callback: nil, success: { (statuses, searchMetadata) -> Void in
                    
                    if let stats = statuses {
                        self.updateBoundaries(stats, min: self.minId, max: self.maxId)
                        
                        for status in statuses! {
                            
                            var tweet = JMCTweet()
                           if  let id = status["id_str"].string
                           {
                              tweet.id = UInt64(id.toInt()!)
                           }

                            tweet.name = status["user"]["name"].string
                            tweet.profileImageURL = status["user"]["profile_image_url_https"].string

                            //parse message
                            if let txt = status["text"].string {
                                tweet.text = txt
                                if let id = status["id_str"].string {
                                      self.parser.parseMessage(txt, messageId: UInt64(id.toInt()!))
                                }
                            }

                            if let profile =  tweet.profileImageURL {
                                
                                var image = self.networkingManager.getImage(profile)
                                if let img = image {
                                    tweet.profileImage = img
                                    self.images[tweet.profileImageURL!] = img
                                    //reload cell
                                    
                                    
                                    
                                }
                            }
                            self.tweets.append(tweet)
                            //reload table
                            if let handler = self.completionHandler {
                                handler()
                            }
                            
                        }
                        
                    }
                }
                , failure: { (error) -> Void in
                    println("Error:\(error)")
                    self.tweets.removeAll(keepCapacity: false)
                    var json = JSONValue(error.debugDescription)
                    var tweet = JMCTweet()
                    tweet.text = json.string
                    self.tweets.append(tweet)
                    ///WARNING:
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
    
    
    class JMCTweet{
        var text:String?
        var name:String?
        var id:UInt64?
        var profileImageURL:String?
        var profileImage:UIImage?
    }
    
    
    
    class TweetCell: UITableViewCell {
        
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet var textView: UITextView!
        
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
    
    extension TweetCell: UITextViewDelegate {
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
        
        func updateCell(path:String, image:UIImage?)->Void{
            //get cell for the given value
            // let filteredArray = tm.tweets.filter({$0.profileImageURL == path})
            var found: Int?
            for i in 0...tm.tweets.count {
                if tm.tweets[i].profileImageURL == path {
                    found = i
                }
                break;
            }
            if let f = found{
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    // do some task
                    dispatch_async(dispatch_get_main_queue()) {
                        // update some UI
                        println("This is run on the main queue, after the previous block")
                        var indexPath = NSIndexPath(forRow: f, inSection: 0)
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
                
            }
            else{
                println("Not found \(found) \(tm.tweets) \(path)")
                
            }
        }
        
        
        func errorHandler(error:String)->Void{
            endRefreshing()
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.
            self.refreshControl = UIRefreshControl()
            self.refreshControl!.tintColor = UIColor.darkGrayColor()
            self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to Refresh")
            self.refreshControl!.addTarget(self, action: "loadMore", forControlEvents: UIControlEvents.ValueChanged)
            
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 44.0
            
            tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCell, upperBond: false, lowerBond: false)
            
        }
        
        func loadMore(){
            tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCell, upperBond: false, lowerBond: true)
            
            //self.endRefreshing()
            
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
            var cell = tableView.dequeueReusableCellWithIdentifier("tweetCell") as TweetCell
            
            cell.titleLabel.text = tweet.name
            cell.textView.text = tweet.text
            if let t = tweet.profileImageURL {
                
                cell.cellImageView.image = tm.images[tweet.profileImageURL!]
                
            }
            
            if (indexPath.row ==  tm.tweets.count - 1)
            {
                tm.getTweetsWithHandler(updateTable, errorHandler: errorHandler,cellHandler: updateCell, upperBond: true, lowerBond: false)
            }
            
            
            return cell
        }
        
        
}

