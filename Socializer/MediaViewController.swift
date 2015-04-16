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
    var vcs:[UIViewController]?

    //var viewControllers = [UIViewController]()

    override func viewDidLoad() {
        self.pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
        self.pageViewController?.delegate = self
        self.pageViewController?.dataSource = self
        self.navigationController?.navigationBar.translucent = false

        var pageControl = UIPageControl.appearance()
       pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.darkGrayColor()

        if let urls = self.urls {
            self.vcs = self.prepareContent(urls)
            if self.vcs?.count > 0{
                self.pageViewController!.setViewControllers([self.vcs![0]], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: { (finished) -> Void in
                    println("finished")
                
            })
          }
        }
        
        addChildViewController(pageViewController!)
        self.view.addSubview(self.pageViewController!.view)
        pageViewController!.didMoveToParentViewController(self)
        
    }
    
    func prepareContent(urls:[NSURL])->[UIViewController]{
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
        
        if let urls = self.urls {
            if let url = viewController.url
            {
              var index = find(urls,url)
                if let index = index {
                    return index
                }
            }
        }
         return NSNotFound
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?{
        
        var index = indexOfViewController(viewController
            as MediaContentController)
        if index < 1 || index == NSNotFound
        {
            return nil
        }
        else{
           return self.vcs![index-1]
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?{
        var index = indexOfViewController(viewController
            as MediaContentController)
        if index >= self.vcs!.count - 1
        {
            return nil
        }
        else{
            return self.vcs![index+1]
        }
        
    }
    
    ///Delegate methods
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return self.vcs!.count
    }
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0;
    }
    
    
}


class MediaContentController:UIViewController, UIWebViewDelegate{
    var url:NSURL?
    var index: NSInteger = 0
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.translucent = false
        
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