//
//  ViewController.swift
//  TestCache
//
//  Created by Thomas on 5/21/17.
//  Copyright © 2017 Thomas. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, AVAssetResourceLoaderDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        setSubviews()
    }
    
    var asset: AVURLAsset!
    var avplayer: AVPlayer!
    var item: AVPlayerItem!
    var currentIndex: Int = 10
    func setSubviews() {
        print("current-------------------------------------\(currentIndex)")
        let key = "\(currentIndex).mp4"
        currentIndex += 1
        playVideo(key: key, url: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
    }
    
    var cacheURL: URL!
    var needCache: Bool!
    
    func playVideo(key: String, url: String) {
        let (realUrl, cacheURL) = CacheManager.shared.getRealUrl(url: url, key: key)
        print(realUrl)
        self.cacheURL = cacheURL
        if let realUrl = realUrl {
            asset = AVURLAsset(url: realUrl)
            needCache = false
        } else {
            asset = AVURLAsset(url: URL(string: url)!)
            needCache = true
        }
        
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        
        item = AVPlayerItem(asset: asset)
        
        avplayer = AVPlayer(playerItem: item)
        
        
        
        
        let layer = AVPlayerLayer(player: avplayer)
        layer.frame = self.view.frame
        layer.backgroundColor = UIColor.red.cgColor
        self.view.layer.addSublayer(layer)
        avplayer.play()
    }
    
    func playVideo() {
        
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        
     /*   let alertController = UIAlertController(title: "系统提示",
                                                message: "视频播放结束", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "好的", style: .default, handler: {
            action in
            print("点击了确定")
        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)*/
        
        if notification.object as? AVPlayerItem  == avplayer.currentItem {
            
                if true == self.needCache {
                let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
                
                let path = CacheManager.shared.cacheBasePath + "/filename.mp4"
                let url = NSURL.fileURL(withPath: path)
                
                exporter.outputURL = self.cacheURL
                exporter.outputFileType = AVFileTypeMPEG4
                
                exporter.exportAsynchronously(completionHandler: {
                    
                    print(exporter.status.rawValue)
                    print(exporter.error)
                })
            }
            self.setSubviews()
        } else {
            print("\n\nERRROOROOROROORORORORORO\n\n")
        }
    }
    
    
    func _getDataFor(_ item: AVPlayerItem, completion: @escaping (Data?) -> ()) {
        guard item.asset.isExportable else {
            completion(nil)
            return
        }
        
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        let sourceVideoTrack = item.asset.tracks(withMediaType: AVMediaTypeVideo).first!
        let sourceAudioTrack = item.asset.tracks(withMediaType: AVMediaTypeAudio).first!
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, item.duration), of: sourceVideoTrack, at: kCMTimeZero)
            try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, item.duration), of: sourceAudioTrack, at: kCMTimeZero)
        } catch(_) {
            completion(nil)
            return
        }
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        var preset: String = AVAssetExportPresetPassthrough
        if compatiblePresets.contains(AVAssetExportPreset1920x1080) { preset = AVAssetExportPreset1920x1080 }
        
        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: preset),
            exportSession.supportedFileTypes.contains(AVFileTypeMPEG4) else {
                completion(nil)
                return
        }
        
        var tempFileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("temp_video_data.mp4", isDirectory: false)
        tempFileUrl = URL(fileURLWithPath: tempFileUrl.path)
        
        exportSession.outputURL = tempFileUrl
        exportSession.outputFileType = AVFileTypeMPEG4
        let startTime = CMTimeMake(0, 1)
        let timeRange = CMTimeRangeMake(startTime, item.duration)
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            print("\(tempFileUrl)")
            print("\(exportSession.error)")
            let data = try? Data(contentsOf: tempFileUrl)
            _ = try? FileManager.default.removeItem(at: tempFileUrl)
            completion(data)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

