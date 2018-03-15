//
//  AudioRecordWaveDrawView.swift
//  AudioRecorderKit
//
//  Created by 黄杰 on 2018/3/15.
//  Copyright © 2018年 黄杰. All rights reserved.
//

import UIKit

class AudioRecordWaveDrawView: UIView {

    /// 当前应该绘制的 sample 的 progress
    var currentDrawProgress: CGFloat = 0.0

    var currentSampleHeight: CGFloat = 0.0

    var sampleWidth: CGFloat = 0.0

    lazy var sampleHeights: [CGFloat] = [CGFloat]()

    func drawSample(with sampleProgress: CGFloat, sampleHeight: CGFloat) {

        currentDrawProgress = sampleProgress
        currentSampleHeight = sampleHeight

        setNeedsDisplay()
        sampleHeights.append(sampleHeight)
    }

    func clear() {

        sampleHeights.removeAll()
        currentDrawProgress = 0.0
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height: bounds.size.height))

        let centerY = bounds.size.height * 0.5

        context.setLineCap(.square)
        context.setStrokeColor(UIColor(red: 241.0/255.0, green: 241.0/255.0, blue: 241.0/255.0, alpha: 1.0).cgColor)
        context.setLineWidth(1.0)

        context.move(to: CGPoint(x: 0.0, y: centerY))
        context.addLine(to: CGPoint(x: bounds.size.width, y: centerY))
        context.strokePath()

        let sampleMargin = (currentDrawProgress * bounds.size.width) / CGFloat(sampleHeights.count)

        for (i, lineHeight) in sampleHeights.enumerated() {
            let startX = CGFloat(i) * sampleMargin
            context.setStrokeColor(UIColor(red: 135.0/255.0, green: 135.0/255.0, blue: 135.0/255.0, alpha: 1.0).cgColor)
            context.setLineWidth(sampleWidth)
            context.move(to: CGPoint(x: startX, y: centerY - lineHeight * 0.5))
            context.addLine(to: CGPoint(x: startX, y: centerY + lineHeight * 0.5))
            context.strokePath()
        }
    }

}
