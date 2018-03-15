//
//  ViewController.swift
//  Example
//
//  Created by 黄杰 on 2018/3/15.
//  Copyright © 2018年 黄杰. All rights reserved.
//=

import UIKit
import AudioRecorderKit
import AVFoundation

class ViewController: UIViewController {

    private lazy var waveView: AudioRecordWaveView = AudioRecordWaveView(frame: CGRect(x: 0.0, y: 60.0, width: UIScreen.main.bounds.size.width, height: 140.0))

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(waveView)

        let audioRecorderManager = AudioRecorderManager.sharedManager

        // 设置时间
        waveView.recordDuration = CGFloat(audioRecorderManager.recorderDuration)

        // 开始动画
        waveView.waveLevelCallbackAction = { [weak audioRecorderManager] in
            guard let sAudioRecorderManager = audioRecorderManager else { return 0.0 }
            var level: CGFloat = 0.0
            sAudioRecorderManager.audioRecorder?.updateMeters()
            guard let currentPower = sAudioRecorderManager.audioRecorder?.averagePower(forChannel: 0) else { return 0.0 }
            level = CGFloat(pow(60.0, currentPower / 40.0))
            return level
        }
    }

    @IBAction func starRecordAction(_ sender: UIButton) {

        // 开始录音
        let audioRecorderManager = AudioRecorderManager.sharedManager

        guard let url = audioRecorderManager.getDefaultDestinationURL() else { return }
        audioRecorderManager.beginRecordWithFileURL(url, audioRecorderDelegate: self)

        // 开始动画
        waveView.startRecordAnimation()
    }

    @IBAction func playAction(_ sender: UIButton) {

        let audioRecorderManager = AudioRecorderManager.sharedManager

        guard let url = audioRecorderManager.getDefaultDestinationURL() else { return }

        // 播放音频
        audioRecorderManager.play(url)
    }
}

extension ViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
}

