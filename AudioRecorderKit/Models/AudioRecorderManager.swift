//
//  AudioRecorderManager.swift
//  Example
//
//  Created by 黄杰 on 2018/3/15.
//  Copyright © 2018年 黄杰. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

extension FileManager {

    static func removeExistingFile(at url: URL) {
        let fileManager = FileManager.default
        let outputPath = url.path
        if fileManager.fileExists(atPath: outputPath) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError {
                print("[SpeechRecognizer] \((#file as NSString).lastPathComponent)[\(#line)], \(#function): \(error.localizedDescription)")
            }
        }
    }
}

public class AudioRecorderManager: NSObject {

    public static let sharedManager = AudioRecorderManager()

    public var recorderDuration: TimeInterval = 3.0

    public var audioRecorder: AVAudioRecorder?

    public var recordTimeoutAction: (() -> Void)?

    private var cachesDirectoryUrl: URL = {
        let cachesDirectoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: cachesDirectoryPath)
    }()

    private var shouldIgnoreStart = false

    private let queue = DispatchQueue(label: "AudioRecorderManager", attributes: [])

    private var audioFileURL: URL?

    fileprivate var player: AVAudioPlayer?

    private var checkRecordTimeoutTimer: Timer?

    public override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(proximityStateChanged), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: UIDevice.current)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension AudioRecorderManager {

    @objc private func checkRecordTimeout(_ timer: Timer) {

        if audioRecorder?.currentTime > recorderDuration {

            endRecord()

            recordTimeoutAction?()
            recordTimeoutAction = nil
        }
    }

    @objc private func proximityStateChanged() {

        if UIDevice.current.proximityState {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            } catch let error {
                print("proximityStateChanged setCategory failed: \(error)")
            }

        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                print("proximityStateChanged setCategory failed: \(error)")
            }
        }
    }
}

extension AudioRecorderManager {

    public func getDefaultDestinationURL() -> URL? {
        let url = cachesDirectoryUrl.appendingPathComponent("audio.aac")
        return url
    }

    public func beginRecordWithFileURL(_ fileURL: URL, audioRecorderDelegate: AVAudioRecorderDelegate) {

        FileManager.removeExistingFile(at: fileURL)

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            print("beginRecordWithFileURL setCategory failed: \(error)")
        }

        do {

            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
            })

            let authAudioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            if authAudioStatus == .restricted || authAudioStatus == .denied {
                requestAuthorizationForAudio()
                return
            }

            prepareAudioRecorderWithFileURL(fileURL, audioRecorderDelegate: audioRecorderDelegate)

            guard let audioRecorder = audioRecorder else { return }

            if audioRecorder.isRecording {
                audioRecorder.stop()
            } else {
                guard !shouldIgnoreStart else { return }
                print("audio record did begin")
                audioRecorder.record()
            }
        }
    }

    private func prepareAudioRecorderWithFileURL(_ fileURL: URL, audioRecorderDelegate: AVAudioRecorderDelegate) {

        audioFileURL = fileURL

        let recorderSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
            AVNumberOfChannelsKey: 1 as AnyObject,
            AVSampleRateKey: 22050.0 as AnyObject,
            ]

        do {
            let audioRecorder = try AVAudioRecorder(url: fileURL, settings: recorderSettings)
            audioRecorder.delegate = audioRecorderDelegate
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord() // creates/overwrites the file at soundFileURL

            self.audioRecorder = audioRecorder

        } catch {
            self.audioRecorder = nil
            print("create AVAudioRecorder error: \(error.localizedDescription)")
        }
    }

    private func requestAuthorizationForAudio() {

        var appName = "APP"

        if let infos = Bundle.main.infoDictionary {
            appName = infos["CFBundleDisplayName"] as? String ?? "APP"
        }

        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if audioAuthStatus != .authorized {

            let message = "允许\(appName)访问你的麦克风？"

            let alertController = UIAlertController(title: "提醒", message: message, preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let settingAction = UIAlertAction(title: "设置", style: .default, handler: { action in
                guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            })

            alertController.addAction(confirmAction)
            alertController.addAction(settingAction)

            guard let appDelegate = UIApplication.shared.delegate, let viewController = appDelegate.window??.rootViewController else { return }

            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    private func startCheckRecordTimeoutTimer() {

        let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkRecordTimeout(_:)), userInfo: nil, repeats: true)

        checkRecordTimeoutTimer = timer

        timer.fire()
    }

    private func endRecord() {

        if let audioRecorder = self.audioRecorder {
            if audioRecorder.isRecording {
                audioRecorder.stop()
            }
        }

        queue.async {
            let _ = try? AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)
        }

        self.checkRecordTimeoutTimer?.invalidate()
        self.checkRecordTimeoutTimer = nil
    }
}

extension AudioRecorderManager {

    public func play(_ url: URL) {

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.volume = 1.0
            self.player?.play()
        } catch {
            let alertController = UIAlertController(title: "Error Occured", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            guard let appDelegate = UIApplication.shared.delegate, let viewController = appDelegate.window??.rootViewController else { return }
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
}
