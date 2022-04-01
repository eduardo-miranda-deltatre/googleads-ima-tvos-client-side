/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import IMAPlugIn
import AVKit

class ViewController: UIViewController {//}, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
  static let ContentURLString =
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"  //NOLINT

  var playerViewController: AVPlayerViewController!
    let imaHandler = ImaHandler()

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black
    setUpContentPlayer()
    setUpAdsLoader()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    requestAds()
  }

  func setUpContentPlayer() {
    // Load AVPlayer with path to our content.
    let contentURL = URL(string: ViewController.ContentURLString)!
    let player = AVPlayer(url: contentURL)
    playerViewController = AVPlayerViewController()
    playerViewController.player = player

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ViewController.contentDidFinishPlaying(_:)),
      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
      object: player.currentItem)

    showContentPlayer()
  }

  func showContentPlayer() {
    self.addChild(playerViewController)
    playerViewController.view.frame = self.view.bounds
    self.view.insertSubview(playerViewController.view, at: 0)
    playerViewController.didMove(toParent: self)
  }

  func hideContentPlayer() {
    // The whole controller needs to be detached so that it doesn't capture resume
    // events from the remote and play content underneath the ad.
    playerViewController.willMove(toParent: nil)
    playerViewController.view.removeFromSuperview()
    playerViewController.removeFromParent()
  }

  func setUpAdsLoader() {
      imaHandler.initializeHandler()
      imaHandler.delegate = self
  }

  func requestAds() {
      imaHandler.requestAds(containerView: view, containerViewController: self, player: playerViewController.player! )
  }

  @objc func contentDidFinishPlaying(_ notification: Notification) {
      imaHandler.contentDidFinishPlaying()
  }

  // MARK: - UIFocusEnvironment

  override var preferredFocusEnvironments: [UIFocusEnvironment] {
      if imaHandler.adBreakActive, let adFocusEnvironment = imaHandler.focusEnvironment() {
      // Send focus to the ad display container during an ad break.
      return [adFocusEnvironment]
    } else {
        // Send focus to the content player otherwise.
      return [playerViewController]
    }
  }
}

extension ViewController: ImaHandlerDelegate {
    func pauseContent() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
        // Pause the content for the SDK to play ads.
            self.playerViewController.player?.pause()
            self.hideContentPlayer()
        // Trigger an update to send focus to the ad display container.
            self.setNeedsFocusUpdate()
        }
    }
    
    func resumeContent() {
        // Resume the content since the SDK is done playing ads (at least for now).
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showContentPlayer()
            self.playerViewController.player?.play()
            // Trigger an update to send focus to the content player.
            self.setNeedsFocusUpdate()
        }
    }
}
