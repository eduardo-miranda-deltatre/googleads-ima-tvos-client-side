//
//  ImaHandler.swift
//  IMAPlugIn
//
//  Created by Eduardo Miranda on 31.03.2022.
//  Copyright © 2022 Greg Schoppe. All rights reserved.
//

import Foundation
import GoogleInteractiveMediaAds
import AVFoundation
import UIKit

public protocol ImaHandlerDelegate: AnyObject {
    func resumeContent()
    func pauseContent()
}

public class ImaHandler: NSObject {
    
    weak public var delegate: ImaHandlerDelegate?

    static let AdTagURLString =
      "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="  //NOLINT
    
    var adsLoader: IMAAdsLoader?
    var adDisplayContainer: IMAAdDisplayContainer?
    var adsManager: IMAAdsManager?
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    public private(set) var adBreakActive = false
    
//    func createContentPlayhead(player: AVPlayer) {
//        // Set up our content playhead and contentComplete callback.
//        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
//    }
    
    public func initializeHandler() {
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader?.delegate = self
    }
    
    public func requestAds(containerView: UIView, containerViewController: UIViewController, player: AVPlayer) {
        // Set up our content playhead and contentComplete callback.
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
      // Create ad display container for ad rendering.
      let adDisplayContainer1 = IMAAdDisplayContainer(adContainer: containerView, viewController: containerViewController)
        adDisplayContainer = adDisplayContainer1
      // Create an ad request with our ad tag, display container, and optional user context.
      let request = IMAAdsRequest(
        adTagUrl: ImaHandler.AdTagURLString,
        adDisplayContainer: adDisplayContainer1,
        contentPlayhead: contentPlayhead,
        userContext: nil)

        adsLoader?.requestAds(with: request)
    }
    
    public func focusEnvironment() -> UIFocusEnvironment? {
        adDisplayContainer?.focusEnvironment
    }
    
    public func contentDidFinishPlaying() {
        adsLoader?.contentComplete()
    }
}

extension ImaHandler: IMAAdsLoaderDelegate {
    
    public func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
      // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
      adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        adsManager?.initialize(with: nil)
    }

    public func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Error loading ads: \(String(describing: adErrorData.adError.message))")
//      showContentPlayer()
//      playerViewController.player?.play()
    }
}

extension ImaHandler: IMAAdsManagerDelegate {
    public func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
      switch event.type {
      case IMAAdEventType.LOADED:
        // Play each ad once it has been loaded.
        adsManager.start()
      case IMAAdEventType.ICON_FALLBACK_IMAGE_CLOSED:
        // Resume playback after the user has closed the dialog.
        adsManager.resume()
      default:
        break
      }
    }

    public func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
      // Fall back to playing content
        print("AdsManager error: \(String(describing: error.message))")
        delegate?.resumeContent()
//      showContentPlayer()
//      playerViewController.player?.play()
    }

    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
      // Pause the content for the SDK to play ads.
//      playerViewController.player?.pause()
//      hideContentPlayer()
      // Trigger an update to send focus to the ad display container.
      adBreakActive = true
        delegate?.pauseContent()
        
//      setNeedsFocusUpdate()
    }

    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
      // Resume the content since the SDK is done playing ads (at least for now).
//      showContentPlayer()
//      playerViewController.player?.play()
      // Trigger an update to send focus to the content player.
      adBreakActive = false
//      setNeedsFocusUpdate()
        delegate?.resumeContent()
    }
}
