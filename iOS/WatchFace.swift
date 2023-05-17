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
    
    @objc func tapped(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let point = gesture.location(in: self)
        let shortEdge = min(bounds.width, bounds.height)
        var entities = [EntityNote]()
        for entity in entityNotes {
            let diff = point - entity.position
            let dist = sqrt(diff.x * diff.x + diff.y * diff.y)
            if dist.isFinite && dist < GraphicArtifects.markRadius * 2 * shortEdge {
                entities.append(entity)
            }
        }
        if entities.count > 0 {
            let width = CGFloat(entities.count) * (UIFont.systemFontSize + 6) + 8
            let height = CGFloat(entities.map { $0.name.count }.reduce(0) { max($0, $1) }) * UIFont.systemFontSize + 30
            var frame = CGRect(x: point.x - width / 2, y: point.y - height / 2, width: width, height: height)
            
            if frame.maxX > bounds.maxX - Self.frameOffset {
                frame.origin.x -= frame.maxX - bounds.maxX + Self.frameOffset
            }
            if frame.maxY > bounds.maxY - Self.frameOffset {
                frame.origin.y -= frame.maxY - bounds.maxY + Self.frameOffset
            }
            if frame.minX >= bounds.minX + Self.frameOffset && frame.minY >= bounds.minY + Self.frameOffset {
                let tooltip = NoteView(frame: frame, entities: entities)
                tooltip.layer.shadowOffset = CGSize(width: 3, height: -3)
                tooltip.layer.shadowRadius = 5
                tooltip.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
                addSubview(tooltip)
            }
        }
    }
}

class NoteView: UIView {
    private var visualEffectView: UIVisualEffectView!
    private var entities: [EntityNote] = []
    
    init(frame frameRect: CGRect, entities: [EntityNote]) {
        self.entities = entities
        super.init(frame: frameRect)
        layer.shadowOffset = CGSize(width: 3, height: -3)
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.2
        layer.shadowColor = UIColor.black.cgColor
        setupView()
    }
    
    override func becomeFirstResponder() -> Bool {
        return false
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
        
        var lastView: UIView? = nil
        for entity in entities.reversed() {
            let entityView = createEntityView(for: entity)
            visualEffectView.contentView.addSubview(entityView)
            
            entityView.translatesAutoresizingMaskIntoConstraints = false
            if let lastView = lastView {
                entityView.trailingAnchor.constraint(equalTo: lastView.leadingAnchor, constant: -6).isActive = true
            } else {
                entityView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -6).isActive = true
            }
            entityView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 6).isActive = true
            entityView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -6).isActive = true
            entityView.widthAnchor.constraint(equalToConstant: UIFont.systemFontSize + 2).isActive = true
            
            lastView = entityView
        }
    }
    
    private func createEntityView(for entity: EntityNote) -> UIView {
        let view = UIView()
        
        let colorMark = UIView()
        colorMark.layer.backgroundColor = entity.color
        let mask = CAShapeLayer()
        mask.path = RoundedRect(rect: CGRect(origin: .zero, size: CGSize(width: 12, height: 12)), nodePos: 0.7 * 6, ankorPos: 0.3 * 6).path
        colorMark.layer.mask = mask
        view.addSubview(colorMark)
        
        let label = UILabel()
        label.text = entity.name.map { String($0) }.joined(separator: "\n")
        label.textAlignment = .right
        label.numberOfLines = 0
        view.addSubview(label)
        
        colorMark.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorMark.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            colorMark.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            colorMark.widthAnchor.constraint(equalToConstant: 12),
            colorMark.heightAnchor.constraint(equalToConstant: 12),
            
            label.topAnchor.constraint(equalTo: colorMark.bottomAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
}
