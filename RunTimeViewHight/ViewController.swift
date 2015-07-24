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
    //println(screenBounds) 
    
    //获取屏幕大小（不包括状态栏高度）
    let viewBounds:CGRect = UIScreen.mainScreen().applicationFrame
    //println(viewBounds)
    
    @IBOutlet weak var view1: UIView!
    var isHighLighted:Bool = false
    var buttonCancel = UIButton(frame:CGRectMake(20, 30, 20, 20))
    var button = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    
    @IBOutlet var containerView: UIView!
    
    
    @IBOutlet weak var btnSwitchImg: UIButton!
    var blnBtnSwitchImg : Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showHalfView()
        
    }
    
    
    func showHalfView(){
        
        view1.frame = CGRectMake(0 , self.screenBounds.height / 2, self.screenBounds.width, self.screenBounds.height * 0.5)
        self.view1.backgroundColor = UIColor.redColor()
        
        containerView.frame = CGRectMake(0 , 0, self.screenBounds.width, self.screenBounds.height)
        
        println("---1---")
        println(view1.frame.width)
        println(view1.frame.height)
        println("--2----")
        println(containerView.frame.width)
        println(containerView.frame.height)
        println("---3---")
        cancelButton()
        loadButton()
    }
    
    
    
    func cancelButton(){
        
        
        //buttonCancel.setTitle("Cancel", forState: UIControlState.Normal)
        let image = UIImage(named: "close_camera") as UIImage?
        buttonCancel.setImage(image, forState: .Normal)
        buttonCancel.frame = CGRectMake(20, 30, 20, 20)
        
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
        
        let image = UIImage(named: "pop-in") as UIImage?
        self.button.setImage(image, forState: .Normal)
        
        //button.setTitle("Show Green", forState: UIControlState.Normal)
        button.frame = CGRectMake(200, 30, 20, 20)
        
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
                    //self.button.setTitle("Show Blue", forState: UIControlState.Normal)
                    let image = UIImage(named: "pop-out") as UIImage?
                    self.button.setImage(image, forState: .Normal)
                    
                    self.isHighLighted = true
                    self.view1.frame = CGRectMake(0 , self.screenBounds.height / 2, self.self.screenBounds.width, self.screenBounds.height * 0.5)
                    self.view1.backgroundColor = UIColor.greenColor()
            
                    transition.subtype = kCATransitionFromBottom
                    self.view1.layer.removeAnimationForKey("transition")
                    self.view1.layer.addAnimation(transition, forKey: "transition")
                
                case true:
                    //self.button.setTitle("Show Green", forState: UIControlState.Normal)
                    let image = UIImage(named: "pop-in") as UIImage?
                    self.button.setImage(image, forState: .Normal)
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
    

    @IBAction func switchBackgroundImage(sender: AnyObject) {
        if blnBtnSwitchImg == true {
            
            //btnSwitchImg.backgroundColor=UIColor.redColor()
            btnSwitchImg.setBackgroundImage(UIImage(named:"image1"),forState:.Normal)
            blnBtnSwitchImg = false
            println("true")
            
        }else{
            
            //btnSwitchImg.backgroundColor=UIColor.orangeColor()
            btnSwitchImg.setBackgroundImage(UIImage(named:"image2"),forState:.Normal)
            blnBtnSwitchImg = true
            println("false")
        }
       

    }
    

}