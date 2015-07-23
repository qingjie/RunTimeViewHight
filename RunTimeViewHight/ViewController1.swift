//
//  ViewController1.swift
//  RunTimeViewHight
//
//  Created by qingjiezhao on 7/22/15.
//  Copyright (c) 2015 qingjiezhao. All rights reserved.
//


import UIKit

class ViewController1: UIViewController {
    
    @IBOutlet weak var view1: UIView!
    var animator = Animator()
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }

    @IBAction func btnTapped(sender: AnyObject) {
        
        //animator.viewPushUp(view1, aniTime: 0.3, animoteKey: nil)
        //animator.viewMoveInFromBottom(view1, aniTime: 0.3, animoteKey: nil)
        //animator.viewPushDown(view1, aniTime: 0.3, animoteKey: nil)
        animator.viewCurdown(view1, aniTime: 0.3)
    }
    
    
    
}