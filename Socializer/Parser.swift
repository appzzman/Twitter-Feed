//
//  Parser.swift
//  Socializer
//
//  Created by Janusz Chudzynski on 4/11/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import Foundation


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
        var parser = Parser()
        self.urls = parser.parseStringForURLS(self.messageText)
        
        
        
        if self.cancelled {
            return
        }
        
    }
}

class Parser{
    let operationQueue:NSOperationQueue = NSOperationQueue() // main operation queue
    var urlHandler:((messageId:UInt64, urls:[NSURL]? )->Void)?//caled when parsing is completed
    
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
    
    
    func parseStringForURLS(str:String)->[NSURL]?{
        
        
        //        var str = "Pascal Hiel |Security|iBeacon|DDIHi Jackie, You might want to take a look at Kontakt.io's cloudbeacon. [http://kontakt.io/introducing-kontakt-io-cloud-beacon/|leo://plh/http%3A*3*3kontakt%2Eio*3introducing-kontakt-io-cloud-beacon*3/JJkQ?_t=tracking_disc] show less"
        
        var detectorError:NSError?;
        let detector:NSDataDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue,error:&detectorError)!
        if countElements(str) == 0 {return nil}
        
        if let error = detectorError
        {
            println(error.debugDescription)
            return nil
        }
        
        var rawMatches:NSArray = detector.matchesInString(str, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, countElements(str)))
        
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