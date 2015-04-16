//
//  FirstViewController.swift
//  Socializer
//
//  Created by sadmin on 3/10/15.
//  Copyright (c) 2015 Janusz Chudzynski. All rights reserved.
//

import UIKit

class FacebookViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tabBarController?.navigationItem.title = "Facebook";
        self.navigationController?.navigationBar.translucent = false

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
 //   https://developers.facebook.com/docs/graph-api/reference/v2.3/page/feed
    

}

