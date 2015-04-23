//
//  NetworkingOperations.swift
//  Socializer
//
//  Created by Janusz Chudzynski on 4/14/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import Foundation
import UIKit

//NSOperation for downloading messages
class ImageDownloader: NSOperation {
    let urlString: String
    let filePath:String
    let keyPath:String
    var image:UIImage?

    
    init(urlString: String, filePath:String, keyPath:String) {
        self.urlString = urlString
        self.filePath = filePath
        self.keyPath = keyPath
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
    
    var currentDownloads :[String:NSOperation] = [String:NSOperation]()//keeps track of current downloads
    var downloadHandler:((url:String, image:UIImage?,keyPath:String )->Void)?//caled when download is completed
    let operationQueue:NSOperationQueue = NSOperationQueue() // main operation queue
    
    
    init(){
    
    }
    
    func downloadImage(filePath:String, url:String, keyPath:String){
        if let operation = currentDownloads[filePath] {
            //do nothing and relax. You are downloading the file right now.
        }
        else{
            
            let operation = ImageDownloader(urlString: url,filePath:filePath, keyPath:keyPath)
            operation.completionBlock = {
                
                self.currentDownloads.removeValueForKey(filePath)
                if let handler = self.downloadHandler {
                    handler(url: url, image:operation.image, keyPath:keyPath)
                }
            }
            
            currentDownloads[filePath] = operation
            self.operationQueue.addOperation(operation)
            
        }
    }
    
    //tries to get image at given path and if it doesn't exist downloads it
    func getImage(url:String, keyPath:String)->UIImage?
    {
        
        let fileManager = NSFileManager.defaultManager()
        var path: String = getPath(url)
        
        if(fileManager.fileExistsAtPath(path))
        {
            return UIImage(contentsOfFile: path)
        }
        else{
            self.downloadImage(path,url:url, keyPath:keyPath)
            return nil;
        }
        
    }
    
    //checks if the file at hashed path name exists
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
    
    //create unique name of the file
    func getPath(url:String)->String{
        let tempDirectoryTemplate = NSTemporaryDirectory()
        return tempDirectoryTemplate.stringByAppendingPathComponent("\(url.hash)")
        
    }
}