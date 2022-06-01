//
//  ViewController.swift
//  AgoraRotationStoryboard
//
//  Created by shaun on 4/27/22.
//

import UIKit
import MessageUI
import AgoraRtcKit

class ViewController: UIViewController {
    private var isSendingLogs = false
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var localView: UIView!
    @IBOutlet private var remoteView: UIView!
    @IBOutlet private var logButton: UIButton!

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

    @IBAction private func sendLogs(_ sender: UIControl?) {
        guard !isSendingLogs else { return }
        DispatchQueue.global(qos: .background).async {
            self.isSendingLogs = true
            defer { self.isSendingLogs = false}
            let urls = self.getLogFiles()
            do {
                if let archiveUrl = try self.zipFiles(urls) {
                    self.sendEmail([archiveUrl])
                } else {
                    self.sendEmail(urls)
                }
            } catch {
                print("Error zipping files ", error)
                self.sendEmail(urls)
            }
        }
    }

    private func getLogFiles() -> [URL] {
        let fm = FileManager.default
        guard let url = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Failed to get cache url")
            return []
        }
        var urls = [URL]()
        for logfile in ["agorasdk.log", "agorasdk_1.log", "agorasdk_2.log", "agorasdk_3.log", "agorasdk_4.log"] {
            let sdklogUrl = url.appendingPathComponent(logfile)
            guard fm.fileExists(atPath: sdklogUrl.path) else { continue }
            urls.append(sdklogUrl)
        }
        print("URLs for logs", urls)
        return urls
    }

    private func zipFiles(_ urls: [URL]) throws -> URL? {
        let fm = FileManager.default
        let dirToZip: URL = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("agora_logs")

        if fm.fileExists(atPath: dirToZip.path) {
            try fm.removeItem(at: dirToZip)
        }

        try fm.createDirectory(at: dirToZip, withIntermediateDirectories: true)
        guard fm.fileExists(atPath: dirToZip.path) else {
            return nil
        }

        for url in urls {
            try fm.copyItem(at: url, to: dirToZip.appendingPathComponent(url.lastPathComponent))
        }

        let coordinator = NSFileCoordinator()
        var error: NSError? = nil
        var archiveUrl: URL? = nil
        coordinator.coordinate(readingItemAt: dirToZip, options: [.forUploading], error: &error) { url in
            do {
                let tempURL = try fm.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: url,
                    create: true
                ).appendingPathComponent("agoraLogs.zip")
                try fm.moveItem(at: url, to: tempURL)
                archiveUrl = tempURL
            } catch {
                return print("Error Zipping/Archiving Files", error)
            }
        }

        return archiveUrl
    }



    private func sendEmail(_ urls: [URL]) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.sendEmail(urls)
            }
            return
        }

          // Modify following variables with your text / recipient
          let recipientEmail = "support@exaple.com"
          let subject = "support email with logs"
          let body = "This is a message that can be edited"

          // Show default mail composer
          if MFMailComposeViewController.canSendMail() {
              let mail = MFMailComposeViewController()
              mail.mailComposeDelegate = self
              mail.setToRecipients([recipientEmail])
              mail.setSubject(subject)
              mail.setMessageBody(body, isHTML: false)
              for url in urls {
                  do {
                      mail.addAttachmentData(try Data(contentsOf: url), mimeType: "text/plain", fileName: url.lastPathComponent)
                  } catch {
                      print("error attaching data", error)
                  }
              }
              present(mail, animated: true)

          } else {
              // Default Messages/Email client is not available
              let alert = UIAlertController(title: "Messages Not Found", message: "The default email client was not found. Please reinstall or contact developer to support your preffered email solution", preferredStyle: .alert)
              alert.addAction(.init(title: "OK", style: .default))
              present(alert, animated: true)
          }
      }
}


extension ViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled, .saved, .sent, .failed:
            controller.dismiss(animated: true)
        }
    }
}
