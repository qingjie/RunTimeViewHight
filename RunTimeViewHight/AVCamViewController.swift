//
//  AVCamViewController.swift
//  AVCam
//
//  Translated by OOPer in cooperation with SHLab.jp on 2015/1/5.
//
/*
File: AVCamViewController.h
File: AVCamViewController.m
Abstract: View controller for camera interface.
Version: 3.1

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

import UIKit

import AVFoundation
import AssetsLibrary

let CapturingStillImageContext = UnsafeMutablePointer<Void>.alloc(1)
let RecordingContext = UnsafeMutablePointer<Void>.alloc(1)
let SessionRunningAndDeviceAuthorizedContext = UnsafeMutablePointer<Void>.alloc(1)

@objc(AVCamViewController)
class AVCamViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet var rootView: UIView!
    
    //获取屏幕大小
    let screenBounds:CGRect = UIScreen.mainScreen().bounds
    //println(screenBounds)
    
    //获取屏幕大小（不包括状态栏高度）
    let viewBounds:CGRect = UIScreen.mainScreen().applicationFrame
    //println(viewBounds)
    
    // For use in the storyboards.
    @IBOutlet private weak var previewView: AVCamPreviewView!
    
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var stillButton: UIButton!
    var isHighLighted:Bool = false
    
    var btnCancel = UIButton(frame:CGRectMake(20, 30, 20, 20))
    var btnPop = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    
    // Session management.
    /// Communicate with the session and other session objects on this queue.
    private var sessionQueue: dispatch_queue_t!
    dynamic private var session: AVCaptureSession!
    private var videoDeviceInput: AVCaptureDeviceInput!
    dynamic private var movieFileOutput: AVCaptureMovieFileOutput!
    dynamic private var stillImageOutput: AVCaptureStillImageOutput!
    
    // Utilities.
    private var backgroundRecordingID: UIBackgroundTaskIdentifier = 0
    dynamic private var deviceAuthorized: Bool = false
    dynamic private var sessionRunningAndDeviceAuthorized: Bool {
        return isSessionRunningAndDeviceAuthorized()
    }
    private var lockInterfaceRotation: Bool = false
    private var runtimeErrorHandlingObserver: AnyObject!
    
    
    private func isSessionRunningAndDeviceAuthorized() -> Bool {
        return self.session.running && self.deviceAuthorized
    }
    
    class func keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized() -> NSSet {
        return NSSet(objects: "session.running", "deviceAuthorized")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "messageHandler:", name: "messageNotification", object: nil)
        
        // Create the AVCaptureSession
        let session = AVCaptureSession()
        self.session = session
        
        // Setup the preview view
        self.previewView.session = session
        
        // Check for device authorization
        self.checkDeviceAuthorizationStatus()
        
        // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
        // Why not do all of this on the main queue?
        // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
        
        let sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        self.sessionQueue = sessionQueue
        
        dispatch_async(sessionQueue) {
            self.backgroundRecordingID = UIBackgroundTaskInvalid
            
            var error: NSError? = nil
            
            
            let videoDevice = AVCamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: .Back)
            let videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as! AVCaptureDeviceInput!
            
            if error != nil {
                println("\(error!)")
            }
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                dispatch_async(dispatch_get_main_queue()) {() in
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    var orientation: UIInterfaceOrientation
                    let application = UIApplication.sharedApplication()
                    if application.respondsToSelector("statusBarOrientation") {
                        orientation = application.statusBarOrientation
                    } else {
                        orientation =  UIApplication.sharedApplication().statusBarOrientation
                    }
                    
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)!
                    //AVLayerVideoGravityResizeAspect 保持视频的宽高比并使播放内容自动适应播放窗口的大小
                    //default one
                    //(self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity  = AVLayerVideoGravityResizeAspect
                    
                    //AVLayerVideoGravityResizeAspectFill 和前者类似，但它是以播放内容填充而不是适应播放窗口的大小
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
                    
                    //AVLayerVideoGravityResize会拉伸播放内容以适应播放窗口
                    //(self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResize
                    
                    
                }
            }
            
            let audioDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).first as! AVCaptureDevice
            
            let audioDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(audioDevice, error: &error) as! AVCaptureDeviceInput!
            
            if error != nil {
                println("\(error!)")
            }
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            }
            
            let movieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput) {
                session.addOutput(movieFileOutput)
                let connection = movieFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                if connection.supportsVideoStabilization {
                    if connection.respondsToSelector("setPreferredVideoStabilizationMode:") {
                        //From iOS8.0 on
                        //setPreferredVideoStabilizationMode
                        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.Auto
                    } else {
                        //connection.enablesVideoStabilizationWhenAvailable = true
                       println("This method is disabled")
                    }
                }
                self.movieFileOutput = movieFileOutput
            }
            
            let stillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput) {
                stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                self.stillImageOutput = stillImageOutput
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.rootView.frame = CGRectMake(0 , screenBounds.height * 0.5, screenBounds.width, 337 )
        self.previewView.frame = CGRectMake(0 , 0, screenBounds.width, 337 )
        println(self.rootView.frame)
        println(self.previewView.frame)

        
        btnCancelCam()
        btnPopCam()
        
        dispatch_async(self.sessionQueue) {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: .Old | .New, context: SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options: .New | .Old, context: CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: .Old | .New, context: RecordingContext)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput.device)
            
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.session, queue: nil) {[weak self]note in
                if self == nil { return }
                dispatch_async(self!.sessionQueue!) {[self]
                    // Manually restarting the session since it must have been stopped due to an error.
                    self!.session.startRunning()
                    self!.recordButton.setTitle(NSLocalizedString("Record", comment: "Recording button record title"), forState: .Normal)
                }
            }
            self.session.startRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        dispatch_async(self.sessionQueue) {
            self.session.stopRunning()
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput.device)
            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver)
            
            self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: SessionRunningAndDeviceAuthorizedContext)
            self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: CapturingStillImageContext)
            self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: RecordingContext)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func shouldAutorotate() -> Bool {
        // Disable autorotation of the interface when recording is in progress.
        return !self.lockInterfaceRotation
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
       
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == CapturingStillImageContext {
            let isCapturingStillImage = change[NSKeyValueChangeNewKey]!.boolValue!
            
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
        } else if context == RecordingContext {
            let isRecording = change[NSKeyValueChangeNewKey]!.boolValue!
            
            dispatch_async(dispatch_get_main_queue()) {
                if isRecording {
                    self.cameraButton.enabled = false
                    self.recordButton.setTitle(NSLocalizedString("Stop", comment: "Recording button stop title"), forState: .Normal)
                    self.recordButton.enabled = true
                } else {
                    self.cameraButton.enabled = true
                    self.recordButton.setTitle(NSLocalizedString("Record", comment: "Recording button record title"), forState: .Normal)
                    self.recordButton.enabled = true
                }
            }
        } else if context == SessionRunningAndDeviceAuthorizedContext {
            let isRunning = change[NSKeyValueChangeNewKey]!.boolValue!
            
            dispatch_async(dispatch_get_main_queue()) {
                if isRunning {
                    self.cameraButton.enabled = true
                    self.recordButton.enabled = true
                    self.stillButton.enabled = true
                } else {
                    self.cameraButton.enabled = false
                    self.recordButton.enabled = false
                    self.stillButton.enabled = false
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    //MARK: Actions
    
    @IBAction private func toggleMovieRecording(AnyObject) {
        self.recordButton.enabled = false
        
        dispatch_async(self.sessionQueue) {
            if !self.movieFileOutput.recording {
                self.lockInterfaceRotation = true
                
                if UIDevice.currentDevice().multitaskingSupported {
                    // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
                    self.backgroundRecordingID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
                }
             
                // Update the orientation on the movie file output video connection before starting recording.
                self.movieFileOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
                
                // Turning OFF flash for video recording
                AVCamViewController.setFlashMode(.Off, forDevice: self.videoDeviceInput.device)
                
                // Start recording to a temporary file.
                let outputFilePath = NSTemporaryDirectory().stringByAppendingPathComponent("movie".stringByAppendingPathExtension("mov")!)
                self.movieFileOutput.startRecordingToOutputFileURL(NSURL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                self.movieFileOutput.stopRecording()
            }
        }
    }
    
    @IBAction func changeCamera(AnyObject) {
        self.cameraButton.enabled = false
        self.recordButton.enabled = false
        self.stillButton.enabled = false
        
        dispatch_async(self.sessionQueue) {
            let currentVideoDevice = self.videoDeviceInput.device
            var preferredPosition = AVCaptureDevicePosition.Unspecified
            let currentPosition = currentVideoDevice.position
            
            switch currentPosition {
            case .Unspecified:
                preferredPosition = .Back
            case .Back:
                preferredPosition = .Front
            case .Front:
                preferredPosition = .Back
            }
            
            let videoDevice = AVCamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            let videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: nil) as! AVCaptureDeviceInput
            
            self.session.beginConfiguration()
            
            self.session.removeInput(self.videoDeviceInput)
            if self.session.canAddInput(videoDeviceInput) {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentVideoDevice)
                
                AVCamViewController.setFlashMode(.Auto, forDevice: videoDevice)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: videoDevice)
                
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                println("D:\(self.session.inputs.count)")
                self.session.addInput(self.videoDeviceInput)
            }
            
            self.session.commitConfiguration()
            
            dispatch_async(dispatch_get_main_queue()) {
                self.cameraButton.enabled = true
                self.recordButton.enabled = true
                self.stillButton.enabled = true
            }
        }
    }
    
    @IBAction func snapStillImage(AnyObject) {
        dispatch_async(self.sessionQueue) {
            // Update the orientation on the still image output video connection before capturing.
            self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
         
            // Flash set to Auto for Still Capture
            AVCamViewController.setFlashMode(.Auto, forDevice: self.videoDeviceInput.device)
            
            // Capture a still image.
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) {imageDataSampleBuffer, error in
                
                if imageDataSampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let image = UIImage(data: imageData)!
                    ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!, completionBlock: nil)
                }
            }
        }
    }
    
    @IBAction private func focusAndExposeTap(gestureRecognizer: UIGestureRecognizer) {
        
        let devicePoint = (self.previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterestForPoint(gestureRecognizer.locationInView(gestureRecognizer.view))
        self.focusWithMode(.AutoFocus, exposeWithMode: .AutoExpose, atDevicePoint: devicePoint, monitorSubjectAreaChange: true)
    }
    
    func subjectAreaDidChange(NSNotification) {
        let devicePoint = CGPointMake(0.5, 0.5)
        self.focusWithMode(.ContinuousAutoFocus , exposeWithMode: .ContinuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
    }
    
    //MARK: File Output Delegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if error != nil {
            println("\(error!)")
        }
        
        self.lockInterfaceRotation = false
        
        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
        let backgroundRecordingID = self.backgroundRecordingID
        self.backgroundRecordingID = UIBackgroundTaskInvalid
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileURL) {assetURL, error in
            if error != nil {
                println("\(error!)")
            }
            
            NSFileManager.defaultManager().removeItemAtURL(outputFileURL, error: nil)
            
            if backgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(backgroundRecordingID)
            }
        }
    }
    
    //MARK: Device Configuration
    
    private func focusWithMode(focusMode: AVCaptureFocusMode, exposeWithMode exposureMode: AVCaptureExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool) {
        dispatch_async(self.sessionQueue) {
            let device = self.videoDeviceInput.device
            var error: NSError? = nil
            if device.lockForConfiguration(&error) {
                if device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if device.exposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposureMode = exposureMode
                    device.exposurePointOfInterest = point
                }
                device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } else {
                println("\(error!)")
            }
        }
    }
    
    private class func setFlashMode(flashMode: AVCaptureFlashMode, forDevice device: AVCaptureDevice) {
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            if device.lockForConfiguration(&error) {
                device.flashMode = flashMode
                device.unlockForConfiguration()
            } else {
                println("\(error!)")
            }
        }
    }
    
    private class func deviceWithMediaType(mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice = devices.first as! AVCaptureDevice
        
        for device in devices as! [AVCaptureDevice] {
            if device.position == position {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
    
    //MARK: UI
    private func runStillImageCaptureAnimation() {
        dispatch_async(dispatch_get_main_queue()) {
            self.previewView.layer.opacity = 0.0
            UIView.animateWithDuration(0.25) {
                self.previewView.layer.opacity = 1.0
            }
        }
    }
    
    private func checkDeviceAuthorizationStatus() {
        let mediaType = AVMediaTypeVideo
        
        AVCaptureDevice.requestAccessForMediaType(mediaType) {granted in
            if granted {
                //Granted access to mediaType
                self.deviceAuthorized = true
            } else {
                //Not granted access to mediaType
                dispatch_async(dispatch_get_main_queue()) {
                    if objc_getClass("UIAlertController") != nil {
                        let alert = UIAlertController(title: "AVCam!",
                            message: "AVCam doesn't have permission to use Camera, please change privacy settings",
                            preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else {
                        UIAlertView(title: "AVCam!",
                            message: "AVCam doesn't have permission to use Camera, please change privacy settings",
                            delegate: nil,
                            cancelButtonTitle: "OK"
                            ).show()
                    }
                    self.deviceAuthorized = false
                }
            }
        }
    }
    
   
    
        
    func btnCancelCam(){
        
        let image = UIImage(named: "close_camera") as UIImage?
        btnCancel.setImage(image, forState: .Normal)
        btnCancel.frame = CGRectMake(20, 30, 20, 20)
        
        //self.view.addSubview(button as UIView)
        
        btnCancel.addTarget(self, action: "btnCancelTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.previewView.addSubview(btnCancel as UIView)
        
    }
    
    func btnCancelTapped(sender: AnyObject){
        
        dispatch_async(dispatch_get_main_queue(), {
            self.rootView.backgroundColor = UIColor.orangeColor()
            self.previewView.frame = CGRectMake(0 , self.screenBounds.height, self.screenBounds.width, self.screenBounds.height * 0.5 )
            self.rootView.frame = CGRectMake(0 , self.screenBounds.height, self.screenBounds.width, self.screenBounds.height * 0.5 )
            
            println("self.screenBounds.height \(self.screenBounds.height )")
            println("self.screenBounds.width \(self.screenBounds.width)")
            
            
            var transition = CATransition()
            transition.duration = 0.1
            transition.type = kCATransitionPush
            transition.subtype = kCATransitionFromBottom
            self.rootView.layer.removeAnimationForKey("transition")
            self.rootView.layer.addAnimation(transition, forKey: "transition")
            
            //self.view1.removeFromSuperview()
        });
    }
    
    
    func btnPopCam(){
        
        let image = UIImage(named: "pop-out") as UIImage?
        self.btnPop.setImage(image, forState: .Normal)
        btnPop.frame = CGRectMake(200, 30, 20, 20)
        btnPop.addTarget(self, action: "btnPopTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.previewView.addSubview(btnPop as UIView)
        
    }
    
    func btnPopTapped(sender: AnyObject){
        
        dispatch_async(dispatch_get_main_queue(), {
            
            var transition = CATransition()
            transition.duration = 0.1
            transition.type = kCATransitionPush
            
            println("--btnPopTapped start-- \(self.isHighLighted)")
            switch self.isHighLighted{
            case true:
              
                let image = UIImage(named: "pop-out") as UIImage?
                self.btnPop.setImage(image, forState: .Normal)
                self.rootView.backgroundColor = UIColor.greenColor()
                
                self.recordButton.frame = CGRectMake(30, 250, 60, 60)
                self.stillButton.frame = CGRectMake(260, 250, 60, 60)
                
                self.previewView.frame = CGRectMake(0 , 0, 375, 337 )
                self.rootView.frame = CGRectMake(0 , self.screenBounds.height * 0.5, 375, 337 )
                
                println("true btnPopTapped previewView \(self.previewView.frame)")
                println("true btnPopTapped rootView \(self.rootView.frame),")
                
                
                
                transition.subtype = kCATransitionFromBottom
                self.rootView.layer.removeAnimationForKey("transition")
                self.rootView.layer.addAnimation(transition, forKey: "transition")
                self.isHighLighted = false
            case false:
                
                let image = UIImage(named: "pop-in") as UIImage?
                self.btnPop.setImage(image, forState: .Normal)
                self.rootView.backgroundColor = UIColor.blueColor()
                
                
                self.recordButton.frame = CGRectMake(30, 570, 60, 60)
                self.stillButton.frame = CGRectMake(260, 570, 60, 60)
                
                self.previewView.frame = CGRectMake(0 , 0, 375, 667 )
                self.rootView.frame = CGRectMake(0 , 0, 375, 667 )
               
                
                
                println("false btnPopTapped previewView \(self.previewView.frame)")
                println("false btnPopTapped rootView \(self.rootView.frame),")
                
                
                
                transition.subtype = kCATransitionFromTop
                self.rootView.layer.removeAnimationForKey("transition")
                self.rootView.layer.addAnimation(transition, forKey: "transition")
                self.isHighLighted = true
                
                
                
            default:
                println("Nothing")
            }
            println("--btnPopTapped end--")
        });
        
    }

    func messageHandler(notification : NSNotification){
        
        println("My name is \(notification.object)")
        viewWillAppear(true)
        
    }
    
    
}