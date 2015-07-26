//
//  ViewController.swift
//  RunTimeViewHight
//
//  Created by qingjiezhao on 7/22/15.
//  Copyright (c) 2015 qingjiezhao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var containerView: UIView!
 
    var btnShow = UIButton(frame:CGRectMake(50, 50, 60, 60))

    //获取屏幕大小
    let screenBounds:CGRect = UIScreen.mainScreen().bounds
    //println(screenBounds)
    
    //获取屏幕大小（不包括状态栏高度）
    let viewBounds:CGRect = UIScreen.mainScreen().applicationFrame
    //println(viewBounds)
    var isShowed:Bool = false
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    
    override func viewWillAppear(animated: Bool) {
        view1.addSubview(containerView)
        btnShowCam()
    }
    
    func btnShowCam(){
        
        btnShow.setTitle("Show", forState: UIControlState.Normal)
        btnShow.backgroundColor = UIColor.blackColor()
        btnShow.frame = CGRectMake(20, 30, 60, 60)
        btnShow.addTarget(self, action: "btnShowTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        view1.addSubview(btnShow as UIView)
    }
    
    func btnShowTapped(sender: AnyObject){
       NSNotificationCenter.defaultCenter().postNotificationName("messageNotification", object: NSString(string:"qingjie zhao"))
       println("Show")
        switch isShowed {
        case true:
            println("true")
            containerView.backgroundColor = UIColor.redColor()
            //containerView
            isShowed = false
        case false:
            println("false")
            containerView.backgroundColor = UIColor.blueColor()
            isShowed = true
        default:break
        }
       //containerView.frame = CGRectMake(0 , self.screenBounds.height * 0.5, 375, 337 )
        
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    


    

}