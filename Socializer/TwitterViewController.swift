//  SecondViewController.swift
//  Socializer
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.

import UIKit





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
        func textViewDidChange(textView: UITextView) {
            
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

        var tm:TweeterManager =  TweeterManager(consumerKey:  "9LUhnfxzbYb7hdaS4bSVZawgZ", consumerSecret:"7XPh2AUJTxEWQRO4SMrTNDsvPZitHXKPlDhzZ9LKhsFsiCC3Ne")
        

        // var networkingManager = Networking()
        func updateTable()->Void{
            
            //get tweets
            self.tableView.reloadData()
            endRefreshing()
        }
        
        func updateCells(messageIds:[UInt64]?) -> Void
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
                    var vc = segue.destinationViewController as! MediaViewController
                    let indexPath = self.tableView.indexPathForCell(k)
                    let tweet = self.tm.tweets[indexPath!.row]
                    vc.urls = tweet.urls
                    
                    
                }
            }
            if(segue.identifier == "showMedia2"){
                if let k  = sender as? UITableViewCell
                {
                    var vc = segue.destinationViewController as! MediaViewController
                    let indexPath = self.tableView.indexPathForCell(k)
                    let tweet = self.tm.tweets[indexPath!.row]
                    tweet.urls?.append(NSURL(string:tweet.messageImageURL!)!)
                    vc.urls = tweet.urls
                    
                    
                }
            }
            
            
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.tabBarController?.navigationItem.title = "Twitter";
            self.navigationController?.navigationBar.translucent = false

            self.refreshControl = UIRefreshControl()
            self.refreshControl!.tintColor = UIColor.darkGrayColor()
            self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to Refresh")
            self.refreshControl!.addTarget(self, action: "loadMore", forControlEvents: UIControlEvents.ValueChanged)
            
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 44.0
            tableView.reloadData()
            
            tm.searchQuery = "iTenWired"
            tm.authenticateApp({ () -> Void in
                  self.tm.getTweetsWithHandler(self.updateTable, errorHandler: self.errorHandler,cellHandler: self.updateCells, upperBond: false, lowerBond: false)
            }, errorHandler: { (error) -> Void in
                println(error)
            })
            
            

            
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
                
            }
            
            
            if let img = tweet.messageImageURL {
                var cell = tableView.dequeueReusableCellWithIdentifier("imageCell") as! ImageCell
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
                var cell = tableView.dequeueReusableCellWithIdentifier("basicCell") as! BasicCell
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

