//
//  MediaViewController.swift
//  Socializer
//
//  Created by Janusz Chudzynski on 4/13/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import Foundation
import UIKit

class MediaViewController:UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate  {

    var urls:[NSURL]?
    var pageViewController:UIPageViewController?
    
    //var viewControllers = [UIViewController]()

    override func viewDidLoad() {
        self.pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
   
        if let urls = self.urls {
            var vcs = self.prepareContent(urls)
            if vcs?.count > 0{
                self.pageViewController!.setViewControllers([vcs![0]], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: { (finished) -> Void in
                    println("finished")
                
            })
          }
        }
        
        addChildViewController(pageViewController!)
        self.view.addSubview(self.pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
        
    }
    
    func prepareContent(urls:[NSURL])->[UIViewController]?{
      //get vc by id otherwise we would have to create programmatically
        var vcs = [MediaContentController]()
        var index = 0 
        for url in urls {
        
            var vc  =  self.storyboard!.instantiateViewControllerWithIdentifier("MediaContentController") as MediaContentController
            vc.url = url
            vc.index = index
            index++
            vcs.append(vc)
        }
            
        return vcs
    }
    
    func indexOfViewController(viewController: MediaContentController) -> Int {
        
        if let dataObject: AnyObject = viewController.index {
            return pageContent.indexOfObject(dataObject)
        } else {
            return NSNotFound
        }
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?{
        
        var index = indexOfViewController(viewController
            as MediaContentController)
        
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?{
        return nil
    }
}


class MediaContentController:UIViewController, UIWebViewDelegate{
    var url:NSURL?
    var index: NSInteger = 0
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let u = self.url {
            let httprequest = NSURLRequest(URL: u)
            self.webView.loadRequest(httprequest)
            self.webView.scalesPageToFit = true
            self.webView.scrollView.scrollEnabled = true
            self.webView.delegate = self
            
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
    }
    
    func webViewDidFinishLoad(webView: UIWebView){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
  
    func webView(webView: UIWebView, didFailLoadWithError error: NSError)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

}