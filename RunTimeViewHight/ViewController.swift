//
//  ViewController.swift
//  RunTimeViewHight
//
//  Created by qingjiezhao on 7/22/15.
//  Copyright (c) 2015 qingjiezhao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //获取屏幕大小
    let screenBounds:CGRect = UIScreen.mainScreen().bounds
    //println(screenBounds) //iPhone6输出：（0.0,0.0,375.0,667.0）
    
    //获取屏幕大小（不包括状态栏高度）
    let viewBounds:CGRect = UIScreen.mainScreen().applicationFrame
    //println(viewBounds) //iPhone6输出：（0.0,20.0,375.0,647.0）
    
    @IBOutlet weak var view1: UIView!
    var isHighLighted:Bool = false
    var buttonCancel = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    var button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showHalfView()
        
    }
    
    
    func showHalfView(){
        
        view1.frame = CGRectMake(0 , self.screenBounds.height / 2, self.screenBounds.width, self.screenBounds.height * 0.5)
        self.view1.backgroundColor = UIColor.redColor()
        
        
        cancelButton()
        loadButton()
    }
    
    
    
    func cancelButton(){
        
        
        buttonCancel.setTitle("Cancel", forState: UIControlState.Normal)
        buttonCancel.frame = CGRectMake(10, 10, 100, 44)
        
        //self.view.addSubview(button as UIView)
        
        buttonCancel.addTarget(self, action: "buttonCancelClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view1.addSubview(buttonCancel as UIView)
        
    }
    
    func buttonCancelClicked(sender: AnyObject){
        
        dispatch_async(dispatch_get_main_queue(), {

            self.view1.frame = CGRectMake(0 , self.viewBounds.height, self.screenBounds.width, self.self.screenBounds.height - self.viewBounds.height)
            self.view1.backgroundColor = UIColor.orangeColor()
            
            var transition = CATransition()
            transition.duration = 0.1
            transition.type = kCATransitionPush
            transition.subtype = kCATransitionFromTop
            self.view1.layer.removeAnimationForKey("transition")
            self.view1.layer.addAnimation(transition, forKey: "transition")
            
            //self.view1.removeFromSuperview()
         });
    }
    

    func loadButton(){
        
        button.setTitle("Show Green", forState: UIControlState.Normal)
        button.frame = CGRectMake(250, 10, 100, 44)
        
        button.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view1.addSubview(button as UIView)

    }
    
    func buttonClicked(sender: AnyObject)
    {
        dispatch_async(dispatch_get_main_queue(), {
            
            var transition = CATransition()
            transition.duration = 0.1
            transition.type = kCATransitionPush
            
            switch self.isHighLighted{
                case false:
                    self.button.setTitle("Show Blue", forState: UIControlState.Normal)
                    self.isHighLighted = true
                    self.view1.frame = CGRectMake(0 , self.screenBounds.height / 2, self.self.screenBounds.width, self.screenBounds.height * 0.5)
                    self.view1.backgroundColor = UIColor.greenColor()
            
                    transition.subtype = kCATransitionFromBottom
                    self.view1.layer.removeAnimationForKey("transition")
                    self.view1.layer.addAnimation(transition, forKey: "transition")
                
                case true:
                    self.button.setTitle("Show Green", forState: UIControlState.Normal)
                    self.isHighLighted = false
                    self.view1.frame = CGRectMake(0 , self.screenBounds.height - self.viewBounds.height + 100, self.screenBounds.width, self.viewBounds.height - 100)
                    self.view1.backgroundColor = UIColor.blueColor()
                
                   
                    transition.subtype = kCATransitionFromTop
                    self.view1.layer.removeAnimationForKey("transition")
                    self.view1.layer.addAnimation(transition, forKey: "transition")
                
                default:
                    println("Nothing")
            }
            
        });
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    //unwind
    @IBAction func close(segue: UIStoryboardSegue) {
        println("closed")
    }
    
    @IBAction func openBottomView(sender: AnyObject) {
       println("unwind")
    }
    
    @IBAction func openCam(sender: AnyObject) {
        
        showHalfView()

    }
    

    

}