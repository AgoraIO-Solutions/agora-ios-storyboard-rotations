//
//  ViewController.swift
//  AgoraRotationStoryboard
//
//  Created by shaun on 4/27/22.
//

import UIKit
import AgoraRtcKit

class ViewController: UIViewController {
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var localView: UIView!
    @IBOutlet private var remoteView: UIView!

    lazy var rtcEngine: AgoraRtcEngineKit = {
        let appID: String =  try! configValue(for: "AGORA_APP_ID")
        let engine = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        engine.enableVideo()
        let vc = AgoraRtcVideoCanvas()
        vc.uid = 0
        vc.renderMode = .hidden
        vc.view = localView
        engine.setupLocalVideo(vc)
        engine.disableAudio()
        return engine
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        localView.clipsToBounds = true
        localView.layer.cornerRadius = 13
        localView.layer.borderWidth = 3
        localView.layer.borderColor = UIColor.white.cgColor

        let result = rtcEngine.joinChannel(byToken: .none, channelId: "test", info: .none, uid: 0) { _, _, _ in

        }

        if result != 0 {
            print("Error: join result \(result)")
        }
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora Error \(errorCode.rawValue)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("Agora Warn \(warningCode.rawValue)")
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
       print("friend joined \(uid)")
       textLabel.isHidden = true
       let videoCanvas = AgoraRtcVideoCanvas()
       videoCanvas.uid = uid
       videoCanvas.renderMode = .hidden
       videoCanvas.view = remoteView
       rtcEngine.setupRemoteVideo(videoCanvas)
    }

}
