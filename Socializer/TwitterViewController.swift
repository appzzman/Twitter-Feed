//
//  SecondViewController.swift
//  Socializer
//
//  Created by sadmin on 3/10/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import UIKit

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


class Networking{
    
    var images:[String] = [String]()
    var currentDownloads :[String:NSOperation] = [String:NSOperation]()
    var downloadHandler:((url:String, image:UIImage? )->Void)!
    
    let operationQueue:NSOperationQueue = NSOperationQueue();
    
    func downloadImageForIndexPath(path:String, url:String){
        if let img = currentDownloads[path] {
            //do nothing and relax. You are downloading the file right now.
        }
        else{

            let operation = ImageDownloader(urlString: url,filePath:path)
            operation.completionBlock = {
                println("Completed")
                self.currentDownloads.removeValueForKey(path)
                self.downloadHandler(url: path, image:operation.image)
   
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
    var networkingManager:Networking

    var swifter: Swifter
    var searchQuery = "twitterAPI"
    var count = 50
    
    var completionHandler:(()->Void)! //updating entire table
    var errorHandler:((error:String)->Void)! // errors
   // var tweetHandler:((path:String)->Void)!//handles updating single tweet
    
    init(){
          swifter = Swifter(consumerKey: "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret: "7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne", appOnly: true)
        networkingManager = Networking()
        self.networkingManager.downloadHandler = {(path:String, image:UIImage?)->Void in
            println("Updated Image")
            var tweet = self.tweets.filter{ $0.profileImageURL == path }.first
            tweet?.profileImage = image;
            //update table view at this index 
            //TODO: fix this crap for displaying in table view
        }
        
        
      
        authenticateApp()
       
        
    }
    

    
    
    func getTweetsWithHandler(completionHandler:()->Void, errorHandler:(error:String)->Void) {
        self.completionHandler = completionHandler
        self.errorHandler = errorHandler
         var sample_text = "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."
   
       // var json = JSONValue(sample_text)
        var t:JMCTweet = JMCTweet()
        t.text = sample_text
        self.tweets.append(t)
        self.completionHandler()

        getRecentTweets()
        
    
    }
    
    //get recent tweets
    func authenticateApp(){
        self.swifter.authorizeAppOnlyWithSuccess({ (accessToken, response) -> Void in
        
            //Create an array sorted by TweetId
            //Every

            
            }, failure: { (error) -> Void in
                println(error)
                self.tweets.removeAll(keepCapacity: false)
                
                var t:JMCTweet = JMCTweet()
                t.text = error.debugDescription
                self.tweets.append(t)
                
                self.completionHandler()

        })
    }
    
    func getRecentTweets(){
    self.swifter.getSearchTweetsWithQuery(
    searchQuery, geocode: nil, lang: nil, locale: nil, resultType: "recent", count: nil, until: nil, sinceID: nil, maxID: nil, includeEntities: nil, callback: nil, success: { (statuses, searchMetadata) -> Void in
        //println(statuses);
        for status in statuses! {
            
                var tweet = JMCTweet()
                tweet.id = status["id_str"].string
                tweet.name = status["user"]["name"].string
                tweet.profileImageURL = status["user"]["profile_image_url_https"].string
                if let profile =  tweet.profileImageURL {
                    tweet.profileImage = self.networkingManager.getImage(profile)
                }
                self.tweets.append(tweet)
        
        }

        
        
        

    }, failure: { (error) -> Void in
        println("Error:\(error)")
        self.tweets.removeAll(keepCapacity: false)
        var json = JSONValue(error.debugDescription)
        var tweet = JMCTweet()
        tweet.text = json.string
        self.tweets.append(tweet)
        self.completionHandler()
        
    })

    }
}


class JMCTweet{
    var text:String?
    var name:String?
    var id:String?
    var profileImageURL:String?
    var profileImage:UIImage?
}

/*

{

       "text" : "Рубан и Тандид — аферисты или посредники? - Новости Украины - From-UA http://t.co/SNNaKjusVS с помощью @twitterapi",
    "user" : {

        "name" : " Украинка",
        
        },
    },
    "id_str" : "581261585961889792",

}
*/

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
    var networkingManager = Networking()
    func updateTable()->Void{
        self.tableView.reloadData()
        endRefreshing()
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
        self.refreshControl!.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44.0
    
        tm.getTweetsWithHandler(updateTable, errorHandler)
    
    }
    
    func refresh(){
        //reload data here 
        //load more 
        /// we need to add a callback here
    
        self.endRefreshing()
        
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
        
        cell.textView.text = tweet.text
        cell.cellImageView.image = tweet.profileImage
        cell.titleLabel.text = tweet.name
        
        return cell
    }
    
    
}

