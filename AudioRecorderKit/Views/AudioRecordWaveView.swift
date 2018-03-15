//
//  AudioRecordWaveView.swift
//  Example
//
//  Created by 黄杰 on 2018/3/15.
//  Copyright © 2018年 黄杰. All rights reserved.
//

import UIKit

public class AudioRecordWaveView: UIView {

    /// 录制的时长
    public var recordDuration: CGFloat = 10.0 {
        didSet {
            waveDrawView.sampleWidth = 2.5
            if recordDuration <= 10.0 {
                displaySampleRateDivide = 2
            } else if recordDuration > 10.0 && recordDuration <= 20.0 {
                displaySampleRateDivide = 2
            } else if recordDuration > 20.0 && recordDuration <= 30.0 {
                displaySampleRateDivide = 3
            } else if recordDuration > 30.0 && recordDuration <= 40.0 {
                displaySampleRateDivide = 4
            } else if recordDuration > 40.0 && recordDuration <= 50.0 {
                displaySampleRateDivide = 5
            } else if recordDuration > 50.0 && recordDuration <= 60.0 {
                displaySampleRateDivide = 6
            } else {
                displaySampleRateDivide = 6
            }
        }
    }

    /// 获取波段波动回调
    public var waveLevelCallbackAction: (() -> CGFloat)?

    fileprivate var recordStartTime: TimeInterval = 0.0

    fileprivate var pauseStartTime: TimeInterval = 0.0

    fileprivate var fakeDisplayLinkSampleRateCount: Int = 0

    fileprivate var displaySampleRateDivide: Int = 2

    private lazy var waveDrawView: AudioRecordWaveDrawView = AudioRecordWaveDrawView()

    fileprivate var displayLink: CADisplayLink?

    private lazy var indicatorLineLayer: CALayer = {
        let layer: CALayer = CALayer()
        layer.frame = CGRect(x: 0.0, y: 0.0, width: 1.0, height: bounds.size.height)
        layer.backgroundColor = UIColor.white.cgColor

        // topDotLayer
        let topDotLayer = CALayer()
        topDotLayer.frame = CGRect(x: -3.0, y: 0.0, width: 6.0, height: 6.0)
        topDotLayer.cornerRadius = 3.0
        topDotLayer.backgroundColor = UIColor.white.cgColor

        // bottomDotLayer
        let bottomDotLayer = CALayer()
        bottomDotLayer.frame = CGRect(x: -3.0, y: bounds.size.height - 6.0, width: 6.0, height: 6.0)
        bottomDotLayer.cornerRadius = 3.0
        bottomDotLayer.backgroundColor = UIColor.white.cgColor

        layer.addSublayer(topDotLayer)
        layer.addSublayer(bottomDotLayer)

        return layer
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        setupSubViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupSubViews()
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        setupSubViews()
    }

    private func setupSubViews() {

        backgroundColor = UIColor.black

        // 波段的宽度
        waveDrawView.sampleWidth = 2.0
        waveDrawView.frame = bounds
        addSubview(waveDrawView)

        // 指示线条
        layer.addSublayer(indicatorLineLayer)

        reset()
    }

}

extension AudioRecordWaveView {

    public func startRecordAnimation() {

        reset()
        recordStartTime = Date().timeIntervalSince1970

        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallBack))
        displayLink?.add(to: RunLoop.current, forMode: .commonModes)
    }

    public func pauseRecordAnimation() {

        displayLink?.isPaused = true
        pauseStartTime = Date().timeIntervalSince1970
    }

    public func resumeRecordAnimation() {

        if pauseStartTime == 0.0 {
            return
        }
        recordStartTime += Date().timeIntervalSince1970 - pauseStartTime
        pauseStartTime = 0.0
        displayLink?.isPaused = false
    }

    public func stopRecordAnimation() {

        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkCallBack() {

        fakeDisplayLinkSampleRateCount += 1

        if fakeDisplayLinkSampleRateCount % displaySampleRateDivide != 0 {
            return
        }

        guard let waveLevelCallbackAction = waveLevelCallbackAction else { return }

        let currentSampleLevel = waveLevelCallbackAction()
        let currentTime = Date().timeIntervalSince1970
        let currentDuration = CGFloat(currentTime - recordStartTime)

        if currentDuration > recordDuration {
            stopRecordAnimation()
            return
        }

        updateUI(with: currentDuration, sampleLevel: currentSampleLevel)
    }
}

extension AudioRecordWaveView {

    public func reset() {

        waveDrawView.clear()

        // 显式事务默认开启动画效果,kCFBooleanTrue关闭
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        var frame = indicatorLineLayer.frame
        frame.origin.x = -4.0
        indicatorLineLayer.frame = frame
        CATransaction.commit()
    }

    private func updateUI(with currentDuration: CGFloat, sampleLevel: CGFloat) {

        let progress = currentDuration / recordDuration

        waveDrawView.drawSample(with: progress, sampleHeight: sampleLevel * bounds.size.height)

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        var frame = indicatorLineLayer.frame
        frame.origin.x = progress * bounds.size.width
        indicatorLineLayer.frame = frame
        CATransaction.commit()
    }
}
