//
//  ViewController.swift
//  VideoSmash
//
//  Created by Jeet Shah on 6/20/15.
//  Copyright (c) 2015 Jeet Shah. All rights reserved.
//

import UIKit
import Foundation
import CoreMedia
import AVFoundation
import AssetsLibrary
import MediaPlayer
import CoreAudio
import CoreFoundation
import Accelerate


class Encoder {
    
    var writer: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var audioInput: AVAssetWriterInput?
    var path: String?
    
    init(path: String, cy: Int, cx: Int, channels: UInt32, rate: Float64) {
        
        self.path = path
        writer = AVAssetWriter(URL: NSURL(fileURLWithPath: path), fileType: AVFileTypeMPEG4, error: nil)
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
        
    
        

        
//        NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//        @320, AVVideoCleanApertureWidthKey,
//        @320, AVVideoCleanApertureHeightKey,
//        @10, AVVideoCleanApertureHorizontalOffsetKey,
//        @10, AVVideoCleanApertureVerticalOffsetKey,
//        nil];
//        
//        
//        
//        NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//        @3, AVVideoPixelAspectRatioHorizontalSpacingKey,
//        @3,AVVideoPixelAspectRatioVerticalSpacingKey,
//        nil];
//        
//        
//        
//        NSDictionary *codecSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//        [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
//        @1,AVVideoMaxKeyFrameIntervalKey,
//        videoCleanApertureSettings, AVVideoCleanApertureKey,
//        //AVVideoScalingModeFit,AVVideoScalingModeKey,
//        videoAspectRatioSettings, AVVideoPixelAspectRatioKey,
//        nil];
//        
//        NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//        AVVideoCodecH264, AVVideoCodecKey,
//        codecSettings,AVVideoCompressionPropertiesKey,
//        @320, AVVideoWidthKey,
//        @320, AVVideoHeightKey,
//        nil];
        
        var videoCleanApurturesSettings = NSDictionary(objectsAndKeys:
            NSNumber(integer: 500), AVVideoCleanApertureWidthKey,
            NSNumber(integer: 500), AVVideoCleanApertureHeightKey,
            NSNumber(integer: 300), AVVideoCleanApertureHorizontalOffsetKey,
            NSNumber(integer: 300), AVVideoCleanApertureVerticalOffsetKey
        )
        
        var videoAspectRatioSettings = NSDictionary(objectsAndKeys:
            NSNumber(integer: 9), AVVideoPixelAspectRatioHorizontalSpacingKey,
            NSNumber(integer: 16), AVVideoPixelAspectRatioVerticalSpacingKey
        )
        
        var settings = NSDictionary(objectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
         NSNumber(integer: cx), AVVideoWidthKey,
         NSNumber(integer: cx), AVVideoHeightKey,
         AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey
        )
       
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings:settings as [NSObject: AnyObject])
        videoInput?.expectsMediaDataInRealTime = true
        
        writer?.addInput(videoInput)
        
        var audiosettings = NSDictionary(objectsAndKeys: NSNumber(integer: kAudioFormatMPEG4AAC),AVFormatIDKey,
                   NSNumber(unsignedInt: channels), AVNumberOfChannelsKey,
                   NSNumber(floatLiteral: rate), AVSampleRateKey,
                   NSNumber(floatLiteral: 64000), AVEncoderBitRateKey
        )
       
        audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audiosettings as [NSObject: AnyObject])
        audioInput?.expectsMediaDataInRealTime = true

        writer?.addInput(audioInput)
    }
    
    func finishWithCompletionHandler(handler: (()-> Void)) {
        
        writer?.finishWritingWithCompletionHandler(handler)
    }
    
    
    func encodeFrame(sampleBuffer: CMSampleBufferRef, bVideo: Bool) -> Bool{
    
    
        if(CMSampleBufferDataIsReady(sampleBuffer) == 1) {
           
            if(writer?.status == AVAssetWriterStatus.Unknown) {
                
                var startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                writer?.startWriting()
               //println("start time \(startTime.value)")
                writer?.startSessionAtSourceTime(startTime)
            }
        }
        if (writer!.status == AVAssetWriterStatus.Failed)
        {
            println("writer error nil")
            return false
        }
        
        if(bVideo) {
            
            if(videoInput?.readyForMoreMediaData == true) {
                
                var success = videoInput?.appendSampleBuffer(sampleBuffer)
                println("writes in video \(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) )")
                return true
            }
            
        } else {
            
            if(audioInput?.readyForMoreMediaData == true) {
                
                var success = audioInput?.appendSampleBuffer(sampleBuffer)
                //println("writes in audio \(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))")
                println("writes in audio \(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) )")
                return true
            }
            
        }
        
        return false
    
    }
    

}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {

    var captureSession: AVCaptureSession?
    var videoCaptureDevice: AVCaptureDevice?
    var audioCaptureDevice: AVCaptureDevice?
    var videoInputDevice: AVCaptureDeviceInput?
    var audioInputDevice: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureQueue: dispatch_queue_t?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var audioDataOutput: AVCaptureAudioDataOutput?
    var videoConnection: AVCaptureConnection?
    var audioConnection: AVCaptureConnection?
    var outputPath = NSTemporaryDirectory() as String
    var totalSeconds: Float64 = 10.00
    var framesPerSecond:Int32 = 30
    var maxDuration: CMTime?
    var toggleCameraSwitch: UIButton = UIButton()
    var progressBar: UIView = UIView()
    var progressThumb = UIView()
    var nextButton: UIButton = UIButton()
    var cameraView: UIView = UIView()
    var progressBarTimer: NSTimer?
    var incInterval: NSTimeInterval = 0.05
    var timer: NSTimer?
    var stopRecording: Bool = false
    var remainingTime : NSTimeInterval = 10.0
    var oldX: CGFloat = 0
    var cx: Int = 0
    var cy: Int = 0
    var channels: UInt32? = 0
    var sampleRate: Float64? = 0
    var encoder: Encoder?
    var isCapturing = false
    var isPaused = false
    var discont = false
    var timeOffset = CMTimeMake(0, 0)
    var lastVideo: CMTime?
    var lastAudio: CMTime?
    var isFirstVideo: Bool = true
    var totalDuration: CMTime = kCMTimeZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutViews()
        captureSession = AVCaptureSession()
        
        captureQueue = dispatch_queue_create("captureQueue", DISPATCH_QUEUE_SERIAL)
        //Add Video Input
        addVideoInputs()
        
        //Add Audio Input
        addAudioInputs()
        
        //Add Capture Preview Layer
        addPreviewLayer()
        stopRecording = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didStopRunning", name: AVCaptureSessionRuntimeErrorNotification, object: captureSession)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            captureSession?.startRunning()
        })
    
    }
    
    func didStopRunning() {
        
        println("capture session stopped")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCapture() {
        
        //objc_sync_enter(self)
            
        if(!isCapturing) {
            
            print("starting cature")
            encoder = nil
            self.isPaused = false
            discont = false
            self.isCapturing = true
        }
        
        //objc_sync_exit(self)
    }
    
    func stopCapture() {
        
       // objc_sync_enter(self)
        self.isCapturing = false
        save()
       // objc_sync_exit(self)
    }
    
    func pauseCapture() {
        
        //objc_sync_enter(self)
        if(self.isCapturing) {
            
            self.isPaused = true
            discont = true
        }
        
        //objc_sync_exit(self)
    }
    
    func resumeCapture() {
        
        //objc_sync_enter(self)
        
        if(self.isPaused) {
            
            self.isPaused = false
        }
        
        //objc_sync_exit(self)

    }
    
    func addVideoInputs() {
        
        videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
       // println("video devices are \(AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count)")
        if let videoDevice = videoCaptureDevice {
            
            videoInputDevice =  AVCaptureDeviceInput(device: videoDevice , error: nil)
            captureSession?.addInput(videoInputDevice)
            setVideoOutput()
            
        } else {
            
            println("video Device not found!")
        }
        
    }
    
    func setVideoOutput() {
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput?.setSampleBufferDelegate(self, queue: captureQueue!)
        captureSession?.addOutput(videoDataOutput)
        videoConnection = videoDataOutput?.connectionWithMediaType(AVMediaTypeVideo)
        videoConnection?.videoOrientation = AVCaptureVideoOrientation.Portrait
        var setCapSettings = NSDictionary(objectsAndKeys: NSNumber(integer: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange),kCVPixelBufferPixelFormatTypeKey,
            AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey)
        videoDataOutput?.videoSettings = setCapSettings as NSDictionary as [NSObject : AnyObject]
        var actual = (videoDataOutput?.videoSettings as [NSObject : AnyObject]?)!
        cy = (actual["Height"]?.integerValue  as Int?)!
        cx = (actual["Width"]?.integerValue as Int?)!
        println("cx and cy are ---- \(cx) and \(cy)")

    }
    
    func addAudioInputs() {
        
        audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        audioInputDevice =  AVCaptureDeviceInput(device: audioCaptureDevice , error: nil)
        captureSession?.addInput(audioInputDevice)
        setAudioOutput()
    }
    
    func setAudioOutput() {
        
        audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput?.setSampleBufferDelegate(self, queue: captureQueue!)
        captureSession?.addOutput(audioDataOutput)
        audioConnection = audioDataOutput?.connectionWithMediaType(AVMediaTypeAudio)
       // println("audio device is \(audioCaptureDevice!.description)")
        
    }
    
    func addPreviewLayer() {
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = CGRect(x: 0, y: progressBar.bounds.height, width: self.view.bounds.width, height: self.view.bounds.width)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    
        let recognizer = UILongPressGestureRecognizer(target: self, action:Selector("holdAction:"))
        recognizer.delegate = self
        self.view.addGestureRecognizer(recognizer)
        cameraView.frame = self.view.frame
        cameraView.layer.addSublayer(previewLayer)
        self.view.addSubview(cameraView)
        self.view.sendSubviewToBack(cameraView)
        self.view.addSubview(toggleCameraSwitch)
        self.view.addSubview(progressBar)
        self.view.addSubview(nextButton)
        
    }
    
    
    func holdAction(recognizer: UILongPressGestureRecognizer) {
        
        
        if recognizer.state == UIGestureRecognizerState.Began {
            
            if(isFirstVideo) {
                
                startCapture()
                isFirstVideo = false
                
            } else {
                
                resumeCapture()
            }
            
            nextButton.hidden = true
            
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            
            pauseCapture()
            println("------------------------------------------------")
            nextButton.hidden = false
        
        } else if ( recognizer.state == UIGestureRecognizerState.Changed) {
            
        }
    }
    
    func save() {
        
         var fileName: String = NSTemporaryDirectory() as String + "capture.mp4"
        dispatch_async(captureQueue!, {
            
            encoder?.finishWithCompletionHandler({
            
                var videoURL = NSURL(fileURLWithPath: fileName)
                var asset = AVURLAsset(URL: videoURL, options: nil)
                print(asset)
//                self.cropMovie(asset)
                var library = ALAssetsLibrary()
                library.writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: fileName), completionBlock: { (NSURl, NSError) -> Void in
                    println("movie saved")
                    NSFileManager.defaultManager().removeItemAtPath(fileName, error: nil)
                })
                
            })
            
            
        })
        
    }
    
    func cropMovie(asset: AVAsset) {
        
        var clipVideoTrack = asset.tracksWithMediaType(AVMediaTypeVideo)
        var track = clipVideoTrack[0] as! AVAssetTrack
        var videoComposition = AVMutableVideoComposition(propertiesOfAsset: asset)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        var resizeWidthFactor = track.naturalSize.width / self.view.bounds.width
        var resizeHeightFactor = track.naturalSize.height / self.view.bounds.height
        println("resize factor === \(resizeWidthFactor) and \(resizeHeightFactor)")
        var cropOffsetX: CGFloat = 0
        var cropOffsetY: CGFloat = 0
        var cropWidth = track.naturalSize.width
        var cropHeight = track.naturalSize.width
        
        println("track width and height is \(track.naturalSize.width)----\(track.naturalSize.height)")
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight)
        var instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(60, 30))
        var transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        var t1 = CGAffineTransformIdentity
        var t2 = CGAffineTransformIdentity
        var size = track.naturalSize
        var txf = track.preferredTransform
        
        // check for the video orientation
        if (size.width == txf.tx && size.height == txf.ty) {
            
            //left
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.width - (cropOffsetX * resizeWidthFactor), track.naturalSize.height - (cropOffsetY * resizeHeightFactor) )
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI) )
            
        } else if (txf.tx == 0 && txf.ty == 0) {
            
            //right
            println("right")
            t1 = CGAffineTransformMakeScale(1, 1)
            t2 = CGAffineTransformRotate(t1,0)
            
        } else if (txf.tx == 0 && txf.ty == size.width) {
            
            //down
            t1 = CGAffineTransformMakeTranslation(0 - (cropOffsetX * resizeWidthFactor), track.naturalSize.width - (cropOffsetY * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, CGFloat(-M_PI_2))
            
        } else {
            
            //up
            t1 = CGAffineTransformMakeTranslation(track.naturalSize.height - (cropOffsetX * resizeWidthFactor) , 0 - (cropOffsetY * resizeHeightFactor))
            t2 = CGAffineTransformRotate(t1, CGFloat(M_PI_2))
        }
        
        var finalTransform = t2
        transformer.setTransform(t2, atTime: kCMTimeZero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        exportVideo(videoComposition, asset: asset)
    }
    
    func exportVideo(videoComposition: AVMutableVideoComposition, asset: AVAsset) {
        var composition = AVMutableComposition()
        
let fileManager = NSFileManager.defaultManager()
    let documentsPath : String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as! String
    let destinationPath: String = documentsPath + "/mergeVideo-\(arc4random()%1000).mp4"
    let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)!
    let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset, presetName:AVAssetExportPresetHighestQuality)
    exporter.videoComposition = videoComposition
    exporter.outputURL = videoPath
    exporter.outputFileType = AVFileTypeMPEG4
    exporter.shouldOptimizeForNetworkUse = true
    exporter.exportAsynchronouslyWithCompletionHandler({
        
        dispatch_async(dispatch_get_main_queue(),{
            
            self.exportDidFinish(exporter)
        })
    })
}

func exportDidFinish(session: AVAssetExportSession) {
    
    var outputURL: NSURL = session.outputURL
    var library: ALAssetsLibrary = ALAssetsLibrary()
    if(library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL)) {
        
        library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: {(url, error) in
        
            var alert = UIAlertView(title: "Success", message: "Video Saved Successfully!", delegate: nil, cancelButtonTitle: "Sweet")
            alert.show()
        })
    }
}


    func layoutViews() {
        
        progressBar.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height * 0.1)
        nextButton.frame = CGRect(x: (self.view.frame.maxX - self.view.frame.width * 0.2 - 2), y: progressBar.frame.maxY - progressBar.frame.height * 0.8 - 2, width: progressBar.frame.width * 0.2 , height: progressBar.frame.height * 0.8)
        
        progressBar.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0)
       
        nextButton.setTitle("Next", forState: UIControlState.Normal)
        nextButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        nextButton.addTarget(self, action: "didPressNextButton:", forControlEvents: UIControlEvents.TouchUpInside)
    
        toggleCameraSwitch.frame = CGRect(x: nextButton.frame.origin.x + 15 , y: progressBar.frame.maxY + 10, width: 40, height: 40)
        toggleCameraSwitch.setImage(UIImage(named: "switchCamera"), forState: UIControlState.Normal)
        toggleCameraSwitch.addTarget(self, action: "toggleCamera:", forControlEvents: UIControlEvents.TouchUpInside)
        
    }
    
    func didPressNextButton(nextButton: UIButton) {
        
        stopCapture()
    }
    
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice {
        
        var rv: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            
            if(device.position == position) {
                
                rv = device as! AVCaptureDevice
            }
            
        }
       // println("return device \(rv)")
        return rv
    }
    
    func toggleCamera(sender: UIButton) {
        
        
        var newInputDevice: AVCaptureDeviceInput = videoInputDevice!
        var position: AVCaptureDevicePosition? = videoInputDevice?.device.position
        var newDevice: AVCaptureDevice?
        var error: NSErrorPointer = NSErrorPointer()
        if(position == AVCaptureDevicePosition.Back) {
            
            newDevice = cameraWithPosition(AVCaptureDevicePosition.Front)
            newInputDevice = AVCaptureDeviceInput.deviceInputWithDevice(newDevice, error: error) as!AVCaptureDeviceInput
            //println("toggle \(newDevice)")
            
        } else if(position == AVCaptureDevicePosition.Front) {
            
            newDevice = cameraWithPosition(AVCaptureDevicePosition.Back)
            newInputDevice = AVCaptureDeviceInput.deviceInputWithDevice(newDevice, error: error) as! AVCaptureDeviceInput
            
        }
        
        captureSession?.stopRunning()
        captureSession?.beginConfiguration()
        
        captureSession?.removeInput(videoInputDevice)
        captureSession?.removeOutput(videoDataOutput)
        videoInputDevice = newInputDevice
        captureSession?.addInput(videoInputDevice)
        setVideoOutput()
        
        //captureSession?.removeOutput(audioDataOutput)
        //setAudioOutput()
        
        captureSession?.commitConfiguration()
        captureSession?.startRunning()
        UIView.transitionWithView(self.view, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {}, completion: nil)
        
        
    }
    
    
    func setAudioFormat(fmt: CMFormatDescriptionRef) {

        var asbd: UnsafePointer<AudioStreamBasicDescription>? = CMAudioFormatDescriptionGetStreamBasicDescription(fmt)
        sampleRate = asbd?.memory.mSampleRate
        channels = asbd?.memory.mChannelsPerFrame
    }
    
    
    func convertCfTypeToSampleBufferRef(cfValue: Unmanaged<CMSampleBufferRef>) -> CMSampleBufferRef{
    
        /* Coded by Vandad Nahavandipoor */
        
        let value = Unmanaged.fromOpaque(
            cfValue.toOpaque()).takeRetainedValue() as CMSampleBufferRef
        return value
    }
    
    func adjustTime(sample: CMSampleBufferRef, offset: CMTime) -> CMSampleBufferRef{
        
        var count =  UnsafeMutablePointer<CMItemCount>.alloc(sizeof(CMItemCount) * 1)
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, count)
        
        var pInfo = UnsafeMutablePointer<CMSampleTimingInfo>.alloc(sizeof(CMSampleTimingInfo) * count.memory)
        CMSampleBufferGetSampleTimingInfoArray(sample, count.memory, pInfo, count)
        println("count is \(count.memory)")
        for (var i: CMItemCount = 0; i < count.memory; i++)
        {
            pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
            pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
        }
        var sout = UnsafeMutablePointer<Unmanaged<CMSampleBufferRef>?>.alloc(sizeof(CMSampleBufferRef) * 1)
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count.memory, pInfo, sout)
        return convertCfTypeToSampleBufferRef(sout.memory!)
    }
    
    func updateProgressBar(inc: Float64) {
        
       // progressThumb.removeFromSuperview()
        let width =  (CGFloat(inc) / 10) * self.progressBar.bounds.width
        println("will update progressBar \(width)")
        progressThumb.frame = CGRect(x: 0, y: 0, width: width, height: self.progressBar.bounds.height)
        progressThumb.backgroundColor = UIColor.redColor()
        progressBar.addSubview(progressThumb)
        
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        
        var bVideo: Bool? = true
     
        
        var newSampleBuffer = sampleBuffer
    
        if(!self.isCapturing || self.isPaused) {
            
            return
        }
        
        if(connection != videoConnection) {
            
            bVideo = false
        }
        
        if(encoder == nil && !bVideo!) {
            
            println("setting up encoder")
            var fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
            self.setAudioFormat(fmt)
            var filePath = NSTemporaryDirectory() as String + "capture.mp4"
            encoder = Encoder(path: filePath, cy: cy, cx: cx, channels: channels!, rate: sampleRate!)
            
        }
    
        if(discont) {
        
            if(bVideo!) {
                
                return
            }
            discont = false
            
            var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            var last = bVideo! ? lastVideo : lastAudio
            
            if(timeOffset.value != 0) {
                
                pts = CMTimeSubtract(pts, timeOffset)
            }
            
            var offset = CMTimeSubtract(pts, last!)
            
            if(timeOffset.value == 0) {
                
                timeOffset = offset
                    
            } else {
                    
                timeOffset = CMTimeAdd(timeOffset, offset)
                
            }

           // println("adjusting thr values timeOffset \(CMTimeGetSeconds(timeOffset))")
        }
        
        if(timeOffset.value > 0) {
            
            println("is old ---  \(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(newSampleBuffer))))")
            newSampleBuffer = self.adjustTime(newSampleBuffer, offset: self.timeOffset)
             println("is new ---- \(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(newSampleBuffer))))")
        }
        
        var pts = CMSampleBufferGetPresentationTimeStamp(newSampleBuffer)
        var dur = CMSampleBufferGetDuration(newSampleBuffer)
        
        if(dur.value > 0) {
            
            pts = CMTimeAdd(pts, dur)
            totalDuration = CMTimeAdd(totalDuration, dur)
            
            println("totalduration is --- \(CMTimeGetSeconds(totalDuration))")
        }
        
        if(bVideo!) {
            
            lastVideo = pts
            
        } else {
            
            lastAudio = pts
        }
        if(CMTimeGetSeconds(totalDuration) <= 10) {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.updateProgressBar(CMTimeGetSeconds(self.totalDuration))
            })

            encoder?.encodeFrame(newSampleBuffer, bVideo: bVideo!)
            
        } else {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.isCapturing = false
                var alertBox = UIAlertView(title: "Info", message: "Maximum Duration Reached!", delegate: nil, cancelButtonTitle: "OK")
                alertBox.show()
                self.nextButton.hidden = false

            })
            
        }
        
    }
}


