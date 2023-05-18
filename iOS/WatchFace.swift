//
//  watchFace.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import UIKit

final class WatchFaceView: UIView {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    private static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 5
    static var currentInstance: WatchFaceView?

    let watchLayout = WatchLayout.shared
    var displayTime: Date? = nil
    var timezone: TimeZone = Calendar.current.timeZone
    var phase: StartingPhase = .init(zeroRing: 0, firstRing: 0, secondRing: 0, thirdRing: 0, fourthRing: 0)
    var timer: Timer?
    var entityNotes: [EntityNote] = []
    
    var location: CGPoint? {
        LocationManager.shared.location ?? watchLayout.location
    }

    private var chineseCalendar = ChineseCalendar(time: Date(), timezone: TimeZone.current, location: nil)
    
    var graphicArtifects = GraphicArtifects()
    private var keyStates = KeyStates()
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        Self.currentInstance = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        Self.currentInstance = self
    }
    
    func setAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: Self.updateInterval, repeats: true) { _ in
            self.drawView(forceRefresh: false)
        }
    }
    
    var isDark: Bool {
        traitCollection.userInterfaceStyle == .dark
    }
    
    func update() {
        let time = displayTime ?? Date()
        chineseCalendar.update(time: time, timezone: timezone, location: location)
    }
    
    func drawView(forceRefresh: Bool) {
        layer.sublayers = []
        if forceRefresh {
            let _ = WatchConnectivityManager.shared.sendLayout(watchLayout.encode(includeOffset: false))
            graphicArtifects = GraphicArtifects()
        }
        update()
        setNeedsDisplay()
    }
    
    func updateSize(with frame: CGRect) {
        self.frame = frame
        drawView(forceRefresh: true)
    }
    
    override func draw(_ rawRect: CGRect) {
        let dirtyRect = rawRect.insetBy(dx: Self.frameOffset, dy: Self.frameOffset)
        entityNotes = layer.update(dirtyRect: dirtyRect, isDark: isDark, watchLayout: watchLayout, chineseCalendar: chineseCalendar, graphicArtifects: graphicArtifects, keyStates: keyStates, phase: phase)
    }
}

final class NoteView: UIView {
    private var visualEffectView: UIVisualEffectView!
    private var entities: [EntityNote] = []
    
    init?(center: CGPoint, bounds: CGRect, entities: [EntityNote]) {
        var entities = entities
        let width: CGFloat
        let height: CGFloat
        if Locale.isChinese {
            width = CGFloat(entities.count) * (UIFont.systemFontSize + 8) + 8
            height = CGFloat(entities.map { $0.name.count }.reduce(0) { max($0, $1) }) * (UIFont.systemFontSize + 6) + 30
        } else {
            for i in 0 ..< entities.count {
                entities[i].name = Locale.translation[entities[i].name] ?? entities[i].name
            }
            width = CGFloat(entities.map { NSAttributedString(string: $0.name, attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)]).boundingRect(with: .zero, context: .none).width }.reduce(0) { max($0, $1) }) * 1.2 + 30
            height = CGFloat(entities.count) * (UIFont.systemFontSize + 9) + 3
        }
        var frame = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
        
        if frame.maxX > bounds.maxX {
            frame.origin.x -= frame.maxX - bounds.maxX
        }
        if frame.maxY > bounds.maxY {
            frame.origin.y -= frame.maxY - bounds.maxY
        }
        if frame.minX >= bounds.minX && frame.minY >= bounds.minY {
            self.entities = entities
            super.init(frame: frame)
            layer.shadowOffset = CGSize(width: 3, height: -3)
            layer.shadowRadius = 5
            layer.shadowOpacity = 0.2
            layer.shadowColor = UIColor.black.cgColor
            setupView()
        } else {
            return nil
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        alpha = 0
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0.0
            }) { _ in
                self.removeFromSuperview()
            }
        }
    }
    
    private func setupView() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        visualEffectView = UIVisualEffectView(effect: blurEffect)
        addSubview(visualEffectView)
        
        visualEffectView.layer.masksToBounds = true
        visualEffectView.frame = bounds
        let mask = CAShapeLayer()
        mask.path = RoundedRect(rect: bounds, nodePos: 10, ankorPos: 2).path
        visualEffectView.layer.mask = mask
        
        let isChinese = Locale.isChinese
        var lastView: UIView? = nil
        for entity in entities.reversed() {
            let entityView = createEntityView(for: entity, isChinese: isChinese)
            visualEffectView.contentView.addSubview(entityView)
            
            entityView.translatesAutoresizingMaskIntoConstraints = false
            if isChinese {
                if let lastView = lastView {
                    entityView.trailingAnchor.constraint(equalTo: lastView.leadingAnchor, constant: -6).isActive = true
                } else {
                    entityView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -6).isActive = true
                }
                entityView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 6).isActive = true
                entityView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -6).isActive = true
                entityView.widthAnchor.constraint(equalToConstant: UIFont.systemFontSize + 2).isActive = true
            } else {
                if let lastView = lastView {
                    entityView.bottomAnchor.constraint(equalTo: lastView.topAnchor, constant: -2).isActive = true
                } else {
                    entityView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -4).isActive = true
                }
                entityView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 6).isActive = true
                entityView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -6).isActive = true
                entityView.heightAnchor.constraint(equalToConstant: UIFont.systemFontSize + 6).isActive = true
            }
            
            lastView = entityView
        }
    }
    
    private func createEntityView(for entity: EntityNote, isChinese: Bool) -> UIView {
        let view = UIView()
        
        let colorMark = UIView()
        colorMark.layer.backgroundColor = entity.color
        let mask = CAShapeLayer()
        mask.path = RoundedRect(rect: CGRect(origin: CGPoint(x: 0.5, y: 0.5), size: CGSize(width: 11, height: 11)), nodePos: 0.7 * 6, ankorPos: 0.3 * 6).path
        colorMark.layer.mask = mask
        view.addSubview(colorMark)
        
        let label = UILabel()
        view.addSubview(label)
        colorMark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        if isChinese {
            label.text = entity.name.map { String($0) }.joined(separator: "\n")
            label.textAlignment = .right
            label.numberOfLines = 0
            
            NSLayoutConstraint.activate([
                colorMark.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
                colorMark.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
                colorMark.widthAnchor.constraint(equalToConstant: 12),
                colorMark.heightAnchor.constraint(equalToConstant: 12),
                
                label.topAnchor.constraint(equalTo: colorMark.bottomAnchor, constant: 4),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                label.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            
        } else {
            label.text = entity.name
            label.textAlignment = .left
            label.numberOfLines = 1
            
            NSLayoutConstraint.activate([
                colorMark.topAnchor.constraint(equalTo: view.topAnchor, constant: 4.5),
                colorMark.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
                colorMark.widthAnchor.constraint(equalToConstant: 12),
                colorMark.heightAnchor.constraint(equalToConstant: 12),
                
                label.leadingAnchor.constraint(equalTo: colorMark.trailingAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                label.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        }
        
        return view
    }
}
