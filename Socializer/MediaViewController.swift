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
        
    }
    
    func prepareContent(urls:[NSURL])->[UIViewController]?{
      //get vc by id otherwise we would have to create programmatically
        return nil
        
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?{
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?{
        return nil
    }
    
    
}


class ContentViewController{
    

}