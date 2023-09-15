//
//  SliderView.swift
//  Chinese Time iOS
//
//  Created by Leo Liu on 6/23/23.
//

import SwiftUI

#if os(macOS)
@MainActor
class ColorPanelObserver {
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(colorPanelWillClose(notification:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }
    
    @objc private func colorPanelWillClose(notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow == NSColorPanel.shared else {
            return
        }
        
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.setAction(nil)
    }
}

class ColorNode: NSControl, NSColorChanging {
    private let callBack: (NSColor) -> Void
    var color: NSColor {
        didSet {
            if let layer = self.layer as? CAShapeLayer {
                layer.fillColor = color.cgColor
            }
        }
    }
    
    init(frame frameRect: NSRect, color: NSColor, action: @escaping (NSColor) -> Void) {
        self.color = color
        self.callBack = action
        super.init(frame: frameRect)
        self.wantsLayer = true
        let colorLayer = CAShapeLayer()
        colorLayer.path = CGPath(ellipseIn: frameRect, transform: nil)
        colorLayer.fillColor = color.cgColor
        self.layer = colorLayer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        self.addGestureRecognizer(clickGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onTap(sender: NSClickGestureRecognizer) {
        let colorPanel = NSColorPanel.shared
        colorPanel.setTarget(nil)
        colorPanel.setAction(nil)
        var position = convert(NSPoint(x: bounds.midX, y: bounds.midY), to: nil)
        position = window?.convertPoint(toScreen: position) ?? position
        position.x -= colorPanel.frame.width / 2
        position.y -= colorPanel.frame.height / 2
        colorPanel.setFrameOrigin(position)
        colorPanel.mode = .RGB
        colorPanel.showsAlpha = true
        colorPanel.colorSpace = .displayP3
        colorPanel.color = color
        colorPanel.orderFrontRegardless()
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(changeColor(_:)))
    }
    
    @objc func changeColor(_ sender: NSColorPanel?) {
        if let newColor = sender?.color {
            color = newColor
            callBack(newColor)
        }
    }
}

struct ColorNodeView: NSViewRepresentable {
    let size: CGSize
    @Binding var color: CGColor
    
    func makeNSView(context: Context) -> ColorNode {
        return ColorNode(frame: NSRect(origin: .zero, size: size), color: NSColor(cgColor: color)!, action: { color = $0.cgColor })
    }
    
    func updateNSView(_ nsView: ColorNode, context: Context) {
        nsView.color = NSColor(cgColor: color)!
    }
}
#endif

@Observable final class ViewGradient {
    private var colors: [CGColor] = []
    private var values: [CGFloat] = []
    var isLoop: Bool = false
    
    var gradientStops: [Gradient.Stop] {
        var stops = [Gradient.Stop]()
        for (value, color) in zip(values, colors) {
            let stop = Gradient.Stop(color: Color(cgColor: color), location: value)
            stops.append(stop)
        }
        stops.sort { $0.location < $1.location }
        if isLoop, let firstStop = stops.first {
            var lastStop = firstStop
            lastStop.location = 1.0
            stops.append(lastStop)
        }
        return stops
    }
    
    var count: Int {
        colors.count
    }
    
    func bindColor(at index: Int) -> Binding<CGColor> {
        Binding(get: {
            self.color(at: index)
        }, set: { newValue in
            if index >= 0 && index < self.colors.count {
                self.colors[index] = newValue
            }
        })
    }
    
    func color(at index: Int) -> CGColor {
        if index >= 0 && index < self.colors.count {
            self.colors[index]
        } else {
            CGColor(gray: 0, alpha: 0)
        }
    }
    
    func value(at index: Int) -> CGFloat {
        if index >= 0 && index < self.values.count {
            self.values[index]
        } else {
            0
        }
    }
    
    func updateValue(at index: Int, with newValue: CGFloat) {
        if index >= 0 && index < self.values.count {
            self.values[index] = newValue
        }
    }
    
    func add(color: CGColor, at value: CGFloat) {
        let index = values.insertionIndex(of: value, comparison: { $0 < $1 })
        colors.insert(color, at: index)
        values.insert(value, at: index)
    }
    
    func remove(at index: Int) {
        if index >= 0 && index < colors.count {
            colors.remove(at: index)
            values.remove(at: index)
        }
    }
    
    func export(allowLoop: Bool = true) -> WatchLayout.Gradient {
        return WatchLayout.Gradient(locations: values, colors: colors, loop: allowLoop && isLoop)
    }
    
    init() {}
    
    init(from gradient: WatchLayout.Gradient, allowLoop: Bool = true) {
        isLoop = allowLoop && gradient.isLoop
        if isLoop {
            colors = gradient.colors.dropLast()
            values = gradient.locations.dropLast()
        } else {
            colors = gradient.colors
            values = gradient.locations
        }
    }
}

struct GradientSliderView: View {
    let barHeight: CGFloat = 5
#if os(iOS)
    let slideHeight: CGFloat = 18
    let pickerSize: CGFloat = 14
#elseif os(macOS)
    let slideHeight: CGFloat = 10
    let pickerSize: CGFloat = 10
#endif
    let padding: CGFloat = 0
    let text: Text
    @Binding var gradient: WatchLayout.Gradient
    let allowLoop: Bool
    
    @State private var viewGradient = ViewGradient()
    @State private var position: (index: Int, pos: CGPoint)? = nil
    
    var body: some View {
        GeometryReader { proxy in
            let size: CGSize = proxy.size
            
            let tapGesture = SpatialTapGesture()
                .onEnded { value in
                    var newPosition = valueForPosition(value.location, in: size)
                    newPosition = max(0, min(1, newPosition))
                    let interpolateColor = gradient.interpolate(at: newPosition)
                    viewGradient.add(color: interpolateColor, at: newPosition)
                }
            
            VStack {
                HStack {
                    text
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    if allowLoop {
                        Text("廻環", comment: "Color Gradient is Loop")
                            .lineLimit(1)
                            .frame(alignment: .trailing)
                            .padding(.leading, 10)
                        Toggle("", isOn: $viewGradient.isLoop)
                            .labelsHidden()
                            .onChange(of: viewGradient.isLoop) { _, _ in
                                gradient = viewGradient.export(allowLoop: allowLoop)
                            }
                    }
                }
                ZStack {
                    
                    // Gradient background
                    LinearGradient(gradient: Gradient(stops: viewGradient.gradientStops), startPoint: .leading, endPoint: .trailing)
                        .frame(height: barHeight)
                        .cornerRadius(size.height / 2)
                        .position(x: size.width / 2 - padding, y: barHeight / 2)
                        .padding(.top, slideHeight - barHeight / 2)
                        .gesture(tapGesture)
                    
                    ForEach(0..<viewGradient.count, id: \.self) { index in
                        let dragGesture = DragGesture()
                            .onChanged { value in
                                if viewGradient.count > 2 && abs(value.location.y - pickerSize) > slideHeight * 2 {
#if os(iOS)
                                    if position == nil {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    }
#endif
                                    let boundedPos = boundByView(point: value.location, bound: size)
                                    position = (index: index, pos: boundedPos)
                                } else {
                                    viewGradient.updateValue(at: index, with: valueForPosition(value.location, in: size))
#if os(iOS)
                                    if position != nil {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    }
#endif
                                    position = nil
                                }
                            }
                            .onEnded { value in
                                if viewGradient.count > 2 && abs(value.location.y - pickerSize) > slideHeight * 2 {
                                    viewGradient.remove(at: index)
                                    position = nil
                                }
                                gradient = viewGradient.export(allowLoop: allowLoop)
                            }
                        
                        let targetPos = if let target = position, target.index == index {
                            target.pos
                        } else {
                            positionForValue(viewGradient.value(at: index), in: size)
                        }
                        let removing = if let target = position {
                            target.index == index
                        } else {
                            false
                        }
#if os(iOS)
                        ColorPicker("", selection: viewGradient.bindColor(at: index))
                            .labelsHidden()
                            .shadow(color: .black.opacity(0.15), radius: 6, x: -3, y: 4)
                            .opacity(removing ? 0.3 : 1.0)
                            .onChange(of: viewGradient.color(at: index)) { _, _ in
                                gradient = viewGradient.export(allowLoop: allowLoop)
                            }
                            .frame(width: pickerSize * 2, height: pickerSize * 2)
                            .position(targetPos)
                            .gesture(dragGesture)
#elseif os(macOS)
                        ColorNodeView(size: CGSize(width: pickerSize * 2, height: pickerSize * 2), color: viewGradient.bindColor(at: index))
                            .shadow(color: .black.opacity(0.3), radius: 2, x: -1, y: 1)
                            .opacity(removing ? 0.3 : 1.0)
                            .onChange(of: viewGradient.color(at: index)) { _, _ in
                                gradient = viewGradient.export(allowLoop: allowLoop)
                            }
                            .frame(width: pickerSize * 2, height: pickerSize * 2)
                            .position(targetPos)
                            .gesture(dragGesture)
#endif
                    }
                }
                .task {
                    viewGradient = ViewGradient(from: gradient, allowLoop: allowLoop)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, padding)
            }
        }
    }
    
    private func boundByView(point: CGPoint, bound: CGSize) -> CGPoint {
        var boundedPoint = point
#if os(iOS)
        let verticalOffset = -pickerSize + barHeight - 33
#elseif os(macOS)
        let verticalOffset = -pickerSize + barHeight - 18
#endif
        boundedPoint.x = max(min(boundedPoint.x, bound.width - padding * 2), 0)
        boundedPoint.y = max(min(boundedPoint.y, bound.height + verticalOffset), verticalOffset)
        return boundedPoint
    }
    
    private func positionForValue(_ value: CGFloat, in size: CGSize) -> CGPoint {
        return CGPoint(x: (size.width - (pickerSize + padding) * 2) * value + pickerSize, y: slideHeight)
    }
    
    private func valueForPosition(_ position: CGPoint, in size: CGSize) -> CGFloat {
        let value = (position.x - pickerSize) / (size.width - (pickerSize + padding) * 2)
        return max(0.0, min(1.0, value))
    }
}

struct SliderView: View {
    @Binding var value: CGFloat
    @State var currentValue: CGFloat = 0
    let label: Text
    
    var body: some View {
#if os(iOS)
        VStack {
            HStack {
                label
                TextField("", value: $currentValue, formatter: {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 2
                    formatter.minimumFractionDigits = 0
                    return formatter
                }())
                .labelsHidden()
                .disabled(true)
                .multilineTextAlignment(.trailing)
            }
            Slider(value: $currentValue, in: 0.0...1.0) { editing in
                if !editing {
                    value = currentValue
                }
            }
            .labelsHidden()
        }
        .onAppear {
            currentValue = value
        }
#elseif os(macOS)
        HStack {
            label
                .frame(maxWidth: 150, alignment: .leading)
            Slider(value: $currentValue, in: 0.0...1.0) { editing in
                if !editing {
                    value = currentValue
                }
            }
            .labelsHidden()
            TextField("", value: $currentValue, formatter: {
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 0
                return formatter
            }())
            .frame(maxWidth: 40)
            .labelsHidden()
            .disabled(true)
            .multilineTextAlignment(.trailing)
        }
        .onAppear {
            currentValue = value
        }
#endif
    }
}

struct ThemedColorSettingCell: View {
    let text: Text
    @Binding var color: CGColor
    @Binding var darkColor: CGColor
    
    var body: some View {
        HStack {
            text
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 10)
            Text("明", comment: "Light theme")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $color)
                .labelsHidden()
                .padding(.trailing, 10)
            Text("暗", comment: "dark theme")
                .lineLimit(1)
                .frame(alignment: .trailing)
                .padding(.horizontal, 5)
            ColorPicker("", selection: $darkColor)
                .labelsHidden()

        }
    }
}

@MainActor
struct RingSetting: View {
    @Environment(\.watchLayout) var watchLayout
    @Environment(\.watchSetting) var watchSetting
#if os(macOS)
    let observer = ColorPanelObserver()
#endif
    
    var body: some View {
        Form {
            Section(header: Text("漸變色", comment: "Gradient Pickers")) {
#if os(iOS)
                let height = 80.0
#else
                let height = 45.0
#endif
                GradientSliderView(text: Text("年輪", comment: "Year Ring Gradient"), gradient: watchLayout.binding(\.firstRing), allowLoop: true)
                    .frame(height: height)
                GradientSliderView(text: Text("月輪", comment: "Month Ring Gradient"), gradient: watchLayout.binding(\.secondRing), allowLoop: true)
                    .frame(height: height)
                GradientSliderView(text: Text("日輪", comment: "Day Ring Gradient"), gradient: watchLayout.binding(\.thirdRing), allowLoop: true)
                    .frame(height: height)
                GradientSliderView(text: Text("大字", comment: "Day Ring Gradient"), gradient: watchLayout.binding(\.centerFontColor), allowLoop: false)
                    .frame(height: height)
            }
            Section(header: Text("透明度", comment: "Transparency sliders")) {
                SliderView(value: watchLayout.binding(\.shadeAlpha), label: Text("殘圈透明", comment: "Inactive ring opacity"))
                SliderView(value: watchLayout.binding(\.majorTickAlpha), label: Text("大刻透明", comment: "Major Tick opacity"))
                SliderView(value: watchLayout.binding(\.minorTickAlpha), label: Text("小刻透明", comment: "Minor Tick opacity"))
            }
            Section(header: Text("明暗主題色", comment: "Watch face colors in light and dark themes")) {
                ThemedColorSettingCell(text: Text("大刻色", comment: "Major tick color"), color: watchLayout.binding(\.majorTickColor), darkColor: watchLayout.binding(\.majorTickColorDark))
                ThemedColorSettingCell(text: Text("小刻色", comment: "Major tick color"), color: watchLayout.binding(\.minorTickColor), darkColor: watchLayout.binding(\.minorTickColorDark))
                ThemedColorSettingCell(text: Text("節氣刻", comment: "Major tick color"), color: watchLayout.binding(\.oddSolarTermTickColor), darkColor: watchLayout.binding(\.oddSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("中氣刻", comment: "Major tick color"), color: watchLayout.binding(\.evenSolarTermTickColor), darkColor: watchLayout.binding(\.evenSolarTermTickColorDark))
                ThemedColorSettingCell(text: Text("小字", comment: "Major tick color"), color: watchLayout.binding(\.fontColor), darkColor: watchLayout.binding(\.fontColorDark))
                ThemedColorSettingCell(text: Text("核", comment: "Major tick color"), color: watchLayout.binding(\.innerColor), darkColor: watchLayout.binding(\.innerColorDark))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text("輪色", comment: "Rings Color Setting"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(NSLocalizedString("畢", comment: "Close settings panel")) {
                watchSetting.presentSetting = false
            }
            .fontWeight(.semibold)
        }
#endif
    }
}

#Preview("Ring Setting") {
    RingSetting()
}
