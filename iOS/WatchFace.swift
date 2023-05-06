//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import UIKit

class WatchFaceView: UIView {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    private static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 5
    static var currentInstance: WatchFaceView?
    static var layoutTemplate: String?

    let watchLayout: WatchLayout
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    var phase: StartingPhase = StartingPhase(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    var timer: Timer?
    
    var location: CGPoint? {
        realLocation ?? watchLayout.location
    }

    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    override init(frame frameRect: CGRect) {
        if let template = Self.layoutTemplate {
            self.watchLayout = WatchLayout(from: template)
        } else {
            self.watchLayout = WatchLayout()
        }
        super.init(frame: frameRect)
        Self.currentInstance = self
    }

    required init?(coder: NSCoder) {
        if let template = Self.layoutTemplate {
            self.watchLayout = WatchLayout(from: template)
        } else {
            self.watchLayout = WatchLayout()
        }
        super.init(coder: coder)
        Self.currentInstance = self
    }
    
    func setAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) { _ in
            self.drawView(forceRefresh: false)
        }
    }
    
    var isDark: Bool {
        self.traitCollection.userInterfaceStyle == .dark
    }
    
    func update(forchRefresh: Bool) {
        let time = displayTime ?? Date()
        if forchRefresh || !chineseCalendar.update(time: time, timezone: timezone, location: location) {
            self.chineseCalendar = ChineseCalendar(time: time, timezone: timezone, location: location)
        }
    }
    
    func drawView(forceRefresh: Bool) {
        layer.sublayers = []
        if forceRefresh {
            let _ = WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
            graphicArtifects = GraphicArtifects()
        }
        update(forchRefresh: forceRefresh)
        setNeedsDisplay()
    }
    
    func updateSize(with frame: CGRect) {
        self.frame = frame
        drawView(forceRefresh: true)
    }
    
    override func draw(_ rawRect: CGRect) {
        let dirtyRect = rawRect.insetBy(dx: Self.frameOffset, dy: Self.frameOffset)
        self.layer.update(dirtyRect: dirtyRect, isDark: isDark, watchLayout: watchLayout, chineseCalendar: chineseCalendar, graphicArtifects: graphicArtifects, keyStates: keyStates, phase: phase)
    }
}
