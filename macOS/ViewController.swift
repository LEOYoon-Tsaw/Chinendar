//
//  ViewController.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/29/23.
//

import AppKit

final class ColorWell: NSColorWell {
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        NSColorPanel.shared.showsAlpha = true
        super.mouseDown(with: event)
    }

    override func resignFirstResponder() -> Bool {
        NSColorPanel.shared.close()
        return super.resignFirstResponder()
    }
}

final class GradientSlider: NSControl, NSColorChanging {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [NSColor] = [.black, .white]
    private var controls = [CAShapeLayer]()
    private var controlsLayer = CALayer()
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    private var previousLocation: CGPoint? = nil
    private var movingControl: CAShapeLayer? = nil
    private var movingIndex: Int? = nil
    private var controlRadius: CGFloat = 0
    private var dragging = false
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors.map { $0.cgColor }, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast().map { NSColor(cgColor: $0)! }
            } else {
                values = newValue.locations
                colors = newValue.colors.map { NSColor(cgColor: $0)! }
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        layer?.addSublayer(trackLayer)
        layer?.addSublayer(controlsLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }

    private func addControl(at value: CGFloat, color: NSColor) {
        let control = CAShapeLayer()
        control.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(value), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
        control.fillColor = color.cgColor
        control.shadowPath = control.path
        control.shadowOpacity = 0.3
        control.shadowRadius = 1.5
        control.shadowOffset = NSMakeSize(0, -1)
        control.lineWidth = 2.0
        controls.append(control)
        controlsLayer.addSublayer(control)
    }
    
    private func initializeControls() {
        controlsLayer.sublayers = []
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[i]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            controls[i].shadowPath = controls[i].path
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height / 3)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: bounds.height / 6, ankorPos: bounds.height / 6 * 0.2).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = NSMakePoint(0, 0)
        trackLayer.endPoint = NSMakePoint(1, 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors
    }
    
    private func moveControl() {
        if let movingControl = movingControl, let movingIndex = movingIndex {
            movingControl.path = CGPath(ellipseIn: NSRect(origin: thumbOriginForValue(values[movingIndex]), size: NSMakeSize(controlRadius * 2, controlRadius * 2)), transform: nil)
            movingControl.shadowPath = movingControl.path
            updateGradient()
        }
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
    }
    
    override func resignFirstResponder() -> Bool {
        movingControl?.strokeColor = nil
        movingControl = nil
        movingIndex = nil
        previousLocation = nil
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        previousLocation = event.locationInWindow
        previousLocation = convert(previousLocation!, from: window?.contentView)
        var hit = false
        var i = 0
        for control in controls {
            if control.path!.contains(previousLocation!) {
                movingControl?.strokeColor = nil
                movingControl = control
                movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
                movingIndex = i
                hit = true
            }
            i += 1
        }
        if !hit {
            var newValue = (previousLocation!.x - trackLayer.frame.minX) / trackLayer.frame.width
            newValue = min(max(newValue, minimumValue), maximumValue)
            let color = gradient.interpolate(at: newValue)
            values.append(newValue)
            colors.append(NSColor(cgColor: color)!)
            addControl(at: newValue, color: NSColor(cgColor: color)!)
            movingIndex = values.count - 1
            movingControl?.strokeColor = nil
            movingControl = controls.last!
            movingControl!.strokeColor = NSColor.controlAccentColor.cgColor
        }
    }

    override func mouseDragged(with event: NSEvent) {
        dragging = true
        if (movingIndex != nil) && (previousLocation != nil) && (movingIndex! < values.count) {
            var location = event.locationInWindow
            location = convert(location, from: window?.contentView)
            let deltaLocation = location.x - previousLocation!.x
            let deltaValue = (maximumValue - minimumValue) * deltaLocation / trackLayer.frame.width
            previousLocation = location
            // Change value
            values[movingIndex!] += deltaValue
            values[movingIndex!] = min(max(values[movingIndex!], minimumValue), maximumValue)
            moveControl()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if !dragging && movingControl != nil && movingIndex != nil {
            NSColorPanel.shared.showsAlpha = true
            let colorPicker = NSColorPanel.shared
            if let currentColor = movingControl?.fillColor {
                colorPicker.color = NSColor(cgColor: currentColor)!
                colorPicker.orderFront(self)
                colorPicker.setTarget(self)
                colorPicker.setAction(#selector(changeColor(_:)))
            }
        }
        dragging = false
        previousLocation = nil
    }
    
    override func keyUp(with event: NSEvent) {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            movingControl?.strokeColor = nil
            movingControl!.removeFromSuperlayer()
            controls.remove(at: movingIndex!)
            values.remove(at: movingIndex!)
            colors.remove(at: movingIndex!)
            movingControl = nil
            movingIndex = nil
            NSColorPanel.shared.close()
            updateGradient()
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 51 && movingControl != nil && movingIndex != nil && values.count > 2 && colors.count > 2 {
            return true
        } else {
            return false
        }
    }
    
    @objc func changeColor(_ sender: NSColorPanel?) {
        if movingControl != nil && movingIndex != nil && sender != nil {
            movingControl!.fillColor = sender!.color.cgColor
            colors[movingIndex!] = sender!.color
            updateGradient()
        }
    }
}

final class ConfigurationViewController: NSViewController, NSWindowDelegate {
    static var currentInstance: ConfigurationViewController? = nil
    @IBOutlet var clearLocationButton: NSButton!
    @IBOutlet var globalMonthPicker: NSPopUpButton!
    @IBOutlet var apparentTimePicker: NSPopUpButton!
    @IBOutlet var datetimePicker: NSDatePicker!
    @IBOutlet var currentTimeToggle: NSButton!
    @IBOutlet var timezonePicker: NSPopUpButton!
    @IBOutlet var latitudeDegreePicker: NSTextField!
    @IBOutlet var latitudeMinutePicker: NSTextField!
    @IBOutlet var latitudeSecondPicker: NSTextField!
    @IBOutlet var latitudeSpherePicker: NSSegmentedControl!
    @IBOutlet var longitudeDegreePicker: NSTextField!
    @IBOutlet var longitudeMinutePicker: NSTextField!
    @IBOutlet var longitudeSecondPicker: NSTextField!
    @IBOutlet var longitudeSpherePicker: NSSegmentedControl!
    @IBOutlet var currentLocationToggle: NSButton!
    @IBOutlet var firstRingGradientPicker: GradientSlider!
    @IBOutlet var secondRingGradientPicker: GradientSlider!
    @IBOutlet var thirdRingGradientPicker: GradientSlider!
    @IBOutlet var shadeAlphaValuePicker: NSSlider!
    @IBOutlet var shadeAlphaValueLabel: NSTextField!
    @IBOutlet var firstRingIsLoop: NSButton!
    @IBOutlet var secondRingIsLoop: NSButton!
    @IBOutlet var thirdRingIsLoop: NSButton!
    @IBOutlet var innerTextGradientPicker: GradientSlider!
    @IBOutlet var minorTickAlphaValuePicker: NSSlider!
    @IBOutlet var minorTickAlphaValueLabel: NSTextField!
    @IBOutlet var majorTickAlphaValuePicker: NSSlider!
    @IBOutlet var majorTickAlphaValueLabel: NSTextField!
    @IBOutlet var innerColorPicker: NSColorWell!
    @IBOutlet var majorTickColorPicker: NSColorWell!
    @IBOutlet var minorTickColorPicker: NSColorWell!
    @IBOutlet var textColorPicker: NSColorWell!
    @IBOutlet var oddStermTickColorPicker: NSColorWell!
    @IBOutlet var evenStermTickColorPicker: NSColorWell!
    @IBOutlet var innerColorPickerDark: NSColorWell!
    @IBOutlet var majorTickColorPickerDark: NSColorWell!
    @IBOutlet var minorTickColorPickerDark: NSColorWell!
    @IBOutlet var textColorPickerDark: NSColorWell!
    @IBOutlet var oddStermTickColorPickerDark: NSColorWell!
    @IBOutlet var evenStermTickColorPickerDark: NSColorWell!
    @IBOutlet var mercuryIndicatorColorPicker: NSColorWell!
    @IBOutlet var venusIndicatorColorPicker: NSColorWell!
    @IBOutlet var marsIndicatorColorPicker: NSColorWell!
    @IBOutlet var jupyterIndicatorColorPicker: NSColorWell!
    @IBOutlet var saturnIndicatorColorPicker: NSColorWell!
    @IBOutlet var moonIndicatorColorPicker: NSColorWell!
    @IBOutlet var eclipseIndicatorColorPicker: NSColorWell!
    @IBOutlet var fullmoonIndicatorColorPicker: NSColorWell!
    @IBOutlet var oddStermIndicatorColorPicker: NSColorWell!
    @IBOutlet var evenStermIndicatorColorPicker: NSColorWell!
    @IBOutlet var sunriseIndicatorColorPicker: NSColorWell!
    @IBOutlet var sunsetIndicatorColorPicker: NSColorWell!
    @IBOutlet var noonIndicatorColorPicker: NSColorWell!
    @IBOutlet var midnightIndicatorColorPicker: NSColorWell!
    @IBOutlet var moonriseIndicatorColorPicker: NSColorWell!
    @IBOutlet var moonsetIndicatorColorPicker: NSColorWell!
    @IBOutlet var moonmeridianIndicatorColorPicker: NSColorWell!
    @IBOutlet var textFontFamilyPicker: NSPopUpButton!
    @IBOutlet var textFontTraitPicker: NSPopUpButton!
    @IBOutlet var centerTextFontFamilyPicker: NSPopUpButton!
    @IBOutlet var centerTextFontTraitPicker: NSPopUpButton!
    @IBOutlet var widthPicker: NSTextField!
    @IBOutlet var heightPicker: NSTextField!
    @IBOutlet var cornerRadiusRatioPicker: NSTextField!
    @IBOutlet var centerTextOffsetPicker: NSTextField!
    @IBOutlet var textHorizontalOffsetPicker: NSTextField!
    @IBOutlet var textVerticalOffsetPicker: NSTextField!
    @IBOutlet var doneButton: NSButton!
    @IBOutlet var themesButton: NSButton!
    @IBOutlet var applyButton: NSButton!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var contentView: NSView!
    
    var panelTimezone = TimeZone(secondsFromGMT: 0)!
    
    func scrollToTop() {
        let maxHeight = max(scrollView.bounds.height, contentView.bounds.height)
        contentView.scroll(NSPoint(x: 0, y: maxHeight))
    }

    func toggle(button: NSButton, with bool: Bool) {
        if bool {
            button.state = .on
        } else {
            button.state = .off
        }
    }

    func readToggle(button: NSButton) -> Bool {
        return button.state == .on
    }

    func populateFontMember(_ picker: NSPopUpButton, inFamily familyPicker: NSPopUpButton) {
        picker.removeAllItems()
        if let family = familyPicker.titleOfSelectedItem {
            let members = NSFontManager.shared.availableMembers(ofFontFamily: family)
            for member in members ?? [[Any]]() {
                if let fontType = member[1] as? String {
                    picker.addItem(withTitle: fontType)
                }
            }
        }
        picker.selectItem(at: 0)
    }

    func populateFontFamilies(_ picker: NSPopUpButton) {
        picker.removeAllItems()
        picker.addItem(withTitle: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!)
        picker.addItems(withTitles: NSFontManager.shared.availableFontFamilies)
    }

    func readFont(family: NSPopUpButton, style: NSPopUpButton) -> NSFont? {
        let size = NSFont.systemFontSize
        let fontFamily: String = family.titleOfSelectedItem!
        let fontTraits: String = style.titleOfSelectedItem!
        if let font = NSFont(name: "\(fontFamily.filter { !$0.isWhitespace })-\(fontTraits.filter { !$0.isWhitespace })", size: size) {
            return font
        }
        let members = NSFontManager.shared.availableMembers(ofFontFamily: fontFamily) ?? [[Any]]()
        for i in 0..<members.count {
            if let memberName = members[i][1] as? String, memberName == fontTraits,
               let weight = members[i][2] as? Int,
               let traits = members[i][3] as? UInt
            {
                return NSFontManager.shared.font(withFamily: fontFamily, traits: NSFontTraitMask(rawValue: traits), weight: weight, size: size)
            }
        }
        if let font = NSFont(name: fontFamily, size: size) {
            return font
        }
        return nil
    }

    func turnLocation(on: Bool) {
        if on {
            clearLocationButton.isEnabled = true
            longitudeSpherePicker.isEnabled = true
            longitudeDegreePicker.isEnabled = true
            longitudeMinutePicker.isEnabled = true
            longitudeSecondPicker.isEnabled = true
            latitudeSpherePicker.isEnabled = true
            latitudeDegreePicker.isEnabled = true
            latitudeMinutePicker.isEnabled = true
            latitudeSecondPicker.isEnabled = true
        } else {
            clearLocationButton.isEnabled = false
            longitudeSpherePicker.isEnabled = false
            longitudeDegreePicker.isEnabled = false
            longitudeMinutePicker.isEnabled = false
            longitudeSecondPicker.isEnabled = false
            latitudeSpherePicker.isEnabled = false
            latitudeDegreePicker.isEnabled = false
            latitudeMinutePicker.isEnabled = false
            latitudeSecondPicker.isEnabled = false
        }
    }

    func presentLocationUnavailable() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("怪哉", comment: "Alert: Location service disabled")
        alert.informativeText = NSLocalizedString("蓋因定位未開啓", comment: "Please enable location service to obtain your longitude and latitude")
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window!)
    }
    
    @IBAction func currentTimeToggled(_ sender: Any) {
        view.window?.makeFirstResponder(datetimePicker)
        datetimePicker.isEnabled = !readToggle(button: currentTimeToggle)
        if !datetimePicker.isEnabled {
            timezonePicker.selectItem(withTitle: Calendar.current.timeZone.identifier)
        }
    }

    @IBAction func currentLocationToggled(_ sender: NSButton) {
        if readToggle(button: currentLocationToggle) {
            LocationManager.shared.enabled = true
            turnLocation(on: false)
            LocationManager.shared.requestLocation { location in
                if location != nil {
                    self.turnLocation(on: false)
                    self.updateLocationUI()
                } else {
                    self.currentLocationToggle.state = .off
                    self.turnLocation(on: true)
                    self.presentLocationUnavailable()
                }
            }
            updateLocationUI()
        } else {
            LocationManager.shared.enabled = false
            LocationManager.shared.location = nil
            turnLocation(on: true)
            updateLocationUI()
        }
    }

    @IBAction func clearLocation(_ sender: Any?) {
        longitudeDegreePicker.doubleValue = 0
        longitudeMinutePicker.doubleValue = 0
        longitudeSecondPicker.doubleValue = 0
        longitudeSpherePicker.selectedSegment = -1

        latitudeDegreePicker.doubleValue = 0
        latitudeMinutePicker.doubleValue = 0
        latitudeSecondPicker.doubleValue = 0
        latitudeSpherePicker.selectedSegment = -1
    }

    @IBAction func timezoneChanged(_ sender: Any) {
        view.window?.makeFirstResponder(timezonePicker)
        if let title = timezonePicker.titleOfSelectedItem {
            let newTimezone = TimeZone(identifier: title)!
            datetimePicker.dateValue = datetimePicker.dateValue.convertToTimeZone(initTimeZone: panelTimezone, timeZone: newTimezone)
            panelTimezone = newTimezone
        }
    }

    @IBAction func firstRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(firstRingIsLoop)
        firstRingGradientPicker.isLoop = readToggle(button: firstRingIsLoop)
        firstRingGradientPicker.updateGradient()
    }

    @IBAction func secondRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(secondRingIsLoop)
        secondRingGradientPicker.isLoop = readToggle(button: secondRingIsLoop)
        secondRingGradientPicker.updateGradient()
    }

    @IBAction func thirdRingIsLoopToggled(_ sender: Any) {
        view.window?.makeFirstResponder(thirdRingIsLoop)
        thirdRingGradientPicker.isLoop = readToggle(button: thirdRingIsLoop)
        thirdRingGradientPicker.updateGradient()
    }

    @IBAction func shadeAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(shadeAlphaValuePicker)
        shadeAlphaValueLabel.stringValue = String(format: "%1.2f", shadeAlphaValuePicker.doubleValue)
    }

    @IBAction func minorTickAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(minorTickAlphaValuePicker)
        minorTickAlphaValueLabel.stringValue = String(format: "%1.2f", minorTickAlphaValuePicker.doubleValue)
    }

    @IBAction func majorTickAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(majorTickAlphaValuePicker)
        majorTickAlphaValueLabel.stringValue = String(format: "%1.2f", majorTickAlphaValuePicker.doubleValue)
    }

    @IBAction func textFontFamilyChange(_ sender: Any) {
        view.window?.makeFirstResponder(textFontFamilyPicker)
        populateFontMember(textFontTraitPicker, inFamily: textFontFamilyPicker)
    }

    @IBAction func centerTextFontFamilyChange(_ sender: Any) {
        view.window?.makeFirstResponder(centerTextFontFamilyPicker)
        populateFontMember(centerTextFontTraitPicker, inFamily: centerTextFontFamilyPicker)
    }

    @IBAction func done(_ sender: Any) {
        view.window?.close()
    }

    @IBAction func apply(_ sender: Any) {
        updateData()
        if let watchFace = WatchFace.currentInstance {
            watchFace.invalidateShadow()
            watchFace.updateSize()
            watchFace._view.drawView(forceRefresh: true)
        }
        updateUI()
        DataContainer.shared.saveLayout(WatchLayout.shared.encode())
    }

    @IBAction func manageThemes(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let nextView = storyboard.instantiateController(withIdentifier: "ThemesList") as! ThemesListViewController
        presentAsSheet(nextView)
    }
    
    func populateTimezonePicker(timezone: TimeZone?) {
        timezonePicker.removeAllItems()
        timezonePicker.addItems(withTitles: TimeZone.knownTimeZoneIdentifiers)
        if let timezone = timezone {
            timezonePicker.selectItem(withTitle: timezone.identifier)
            panelTimezone = timezone
        } else {
            let currentTimezone = Calendar.current.timeZone
            timezonePicker.selectItem(withTitle: currentTimezone.identifier)
            panelTimezone = currentTimezone
        }
    }
    
    func updateData() {
        let watchView = WatchFace.currentInstance!._view
        let watchLayout = WatchLayout.shared
        ChineseCalendar.globalMonth = globalMonthPicker.selectedItem! == globalMonthPicker.item(at: 0)!
        ChineseCalendar.apparentTime = apparentTimePicker.selectedItem! == apparentTimePicker.item(at: 1)!
        if readToggle(button: currentTimeToggle) {
            watchView.displayTime = nil
        } else {
            let selectedDate = datetimePicker.dateValue.convertToTimeZone(initTimeZone: panelTimezone, timeZone: Calendar.current.timeZone)
            let secondDiff = Calendar.current.component(.second, from: selectedDate)
            watchView.displayTime = selectedDate.advanced(by: -Double(secondDiff))
        }
        if let title = timezonePicker.titleOfSelectedItem {
            watchView.timezone = TimeZone(identifier: title)!
        }
        if readToggle(button: currentLocationToggle) {
            LocationManager.shared.enabled = true
        } else {
            LocationManager.shared.enabled = false
            
            if latitudeSpherePicker.selectedSegment == -1 || longitudeSpherePicker.selectedSegment == -1 {
                watchLayout.location = nil
            } else {
                LocationManager.shared.enabled = false
                var latitude = latitudeDegreePicker.doubleValue
                latitude += latitudeMinutePicker.doubleValue / 60
                latitude += latitudeSecondPicker.doubleValue / 3600
                latitude *= latitudeSpherePicker.selectedSegment == 0 ? 1 : -1
                
                var longitude = longitudeDegreePicker.doubleValue
                longitude += longitudeMinutePicker.doubleValue / 60
                longitude += longitudeSecondPicker.doubleValue / 3600
                longitude *= longitudeSpherePicker.selectedSegment == 0 ? 1 : -1
                watchLayout.location = NSMakePoint(latitude, longitude)
            }
        }
        
        watchLayout.firstRing = firstRingGradientPicker.gradient
        watchLayout.secondRing = secondRingGradientPicker.gradient
        watchLayout.thirdRing = thirdRingGradientPicker.gradient
        watchLayout.shadeAlpha = shadeAlphaValuePicker.doubleValue
        watchLayout.centerFontColor = innerTextGradientPicker.gradient
        watchLayout.innerColor = innerColorPicker.color.cgColor
        watchLayout.majorTickColor = majorTickColorPicker.color.cgColor
        watchLayout.minorTickColor = minorTickColorPicker.color.cgColor
        watchLayout.minorTickAlpha = minorTickAlphaValueLabel.doubleValue
        watchLayout.majorTickAlpha = majorTickAlphaValueLabel.doubleValue
        watchLayout.fontColor = textColorPicker.color.cgColor
        watchLayout.oddSolarTermTickColor = oddStermTickColorPicker.color.cgColor
        watchLayout.evenSolarTermTickColor = evenStermTickColorPicker.color.cgColor
        watchLayout.innerColorDark = innerColorPickerDark.color.cgColor
        watchLayout.majorTickColorDark = majorTickColorPickerDark.color.cgColor
        watchLayout.minorTickColorDark = minorTickColorPickerDark.color.cgColor
        watchLayout.fontColorDark = textColorPickerDark.color.cgColor
        watchLayout.oddSolarTermTickColorDark = oddStermTickColorPickerDark.color.cgColor
        watchLayout.evenSolarTermTickColorDark = evenStermTickColorPickerDark.color.cgColor
        watchLayout.planetIndicator = [
            mercuryIndicatorColorPicker.color.cgColor,
            venusIndicatorColorPicker.color.cgColor,
            marsIndicatorColorPicker.color.cgColor,
            jupyterIndicatorColorPicker.color.cgColor,
            saturnIndicatorColorPicker.color.cgColor,
            moonIndicatorColorPicker.color.cgColor
        ]
        watchLayout.eclipseIndicator = eclipseIndicatorColorPicker.color.cgColor
        watchLayout.fullmoonIndicator = fullmoonIndicatorColorPicker.color.cgColor
        watchLayout.oddStermIndicator = oddStermIndicatorColorPicker.color.cgColor
        watchLayout.evenStermIndicator = evenStermIndicatorColorPicker.color.cgColor
        watchLayout.sunPositionIndicator = [
            midnightIndicatorColorPicker.color.cgColor,
            sunriseIndicatorColorPicker.color.cgColor,
            noonIndicatorColorPicker.color.cgColor,
            sunsetIndicatorColorPicker.color.cgColor
        ]
        watchLayout.moonPositionIndicator = [
            moonriseIndicatorColorPicker.color.cgColor,
            moonmeridianIndicatorColorPicker.color.cgColor,
            moonsetIndicatorColorPicker.color.cgColor
        ]
        watchLayout.textFont = readFont(family: textFontFamilyPicker, style: textFontTraitPicker) ?? watchLayout.textFont
        watchLayout.centerFont = readFont(family: centerTextFontFamilyPicker, style: centerTextFontTraitPicker) ?? watchLayout.centerFont
        watchLayout.watchSize = NSMakeSize(max(0, widthPicker.doubleValue), max(0, heightPicker.doubleValue))
        watchLayout.cornerRadiusRatio = max(0, min(1, cornerRadiusRatioPicker.doubleValue))
        watchLayout.centerTextOffset = centerTextOffsetPicker.doubleValue
        watchLayout.horizontalTextOffset = textHorizontalOffsetPicker.doubleValue
        watchLayout.verticalTextOffset = textVerticalOffsetPicker.doubleValue
    }
    
    func updateLocationUI() {
        guard let watchView = WatchFace.currentInstance?._view else { return }
        if let location = watchView.location {
            var latitude = location.x
            latitudeSpherePicker.selectedSegment = latitude >= 0 ? 0 : 1
            latitude = abs(latitude)
            latitudeDegreePicker.doubleValue = floor(latitude)
            latitude = (latitude - floor(latitude)) * 60
            latitudeMinutePicker.doubleValue = floor(latitude)
            latitude = (latitude - floor(latitude)) * 60
            latitudeSecondPicker.doubleValue = latitude
            
            var longitude = location.y
            longitudeSpherePicker.selectedSegment = longitude >= 0 ? 0 : 1
            longitude = abs(longitude)
            longitudeDegreePicker.doubleValue = floor(longitude)
            longitude = (longitude - floor(longitude)) * 60
            longitudeMinutePicker.doubleValue = floor(longitude)
            longitude = (longitude - floor(longitude)) * 60
            longitudeSecondPicker.doubleValue = longitude
            
            if LocationManager.shared.location != nil {
                currentLocationToggle.state = .on
            } else {
                currentLocationToggle.state = .off
            }
            
            apparentTimePicker.isEnabled = true
            apparentTimePicker.selectItem(at: ChineseCalendar.apparentTime ? 1 : 0)
        } else {
            apparentTimePicker.isEnabled = false
            apparentTimePicker.selectItem(at: 0)
            clearLocation(nil)
        }
    }
    
    func updateUI() {
        guard let watchView = WatchFace.currentInstance?._view else { return }
        let watchLayout = WatchLayout.shared
        globalMonthPicker.selectItem(at: ChineseCalendar.globalMonth ? 0 : 1)
        populateTimezonePicker(timezone: watchView.timezone)
        if let time = watchView.displayTime {
            datetimePicker.dateValue = time.convertToTimeZone(initTimeZone: Calendar.current.timeZone, timeZone: panelTimezone)
            datetimePicker.isEnabled = true
            currentTimeToggle.state = .off
        } else {
            datetimePicker.dateValue = Date().convertToTimeZone(initTimeZone: Calendar.current.timeZone, timeZone: panelTimezone)
            datetimePicker.isEnabled = false
            currentTimeToggle.state = .on
        }
        updateLocationUI()
        firstRingGradientPicker.gradient = watchLayout.firstRing
        secondRingGradientPicker.gradient = watchLayout.secondRing
        thirdRingGradientPicker.gradient = watchLayout.thirdRing
        toggle(button: firstRingIsLoop, with: watchLayout.firstRing.isLoop)
        toggle(button: secondRingIsLoop, with: watchLayout.secondRing.isLoop)
        toggle(button: thirdRingIsLoop, with: watchLayout.thirdRing.isLoop)
        shadeAlphaValuePicker.doubleValue = Double(watchLayout.shadeAlpha)
        shadeAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.shadeAlpha)
        innerTextGradientPicker.gradient = watchLayout.centerFontColor
        innerColorPicker.color = NSColor(cgColor: watchLayout.innerColor)!
        majorTickColorPicker.color = NSColor(cgColor: watchLayout.majorTickColor)!
        minorTickColorPicker.color = NSColor(cgColor: watchLayout.minorTickColor)!
        minorTickAlphaValuePicker.doubleValue = Double(watchLayout.minorTickAlpha)
        minorTickAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.minorTickAlpha)
        majorTickAlphaValuePicker.doubleValue = Double(watchLayout.majorTickAlpha)
        majorTickAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.majorTickAlpha)
        textColorPicker.color = NSColor(cgColor: watchLayout.fontColor)!
        oddStermTickColorPicker.color = NSColor(cgColor: watchLayout.oddSolarTermTickColor)!
        evenStermTickColorPicker.color = NSColor(cgColor: watchLayout.evenSolarTermTickColor)!
        innerColorPickerDark.color = NSColor(cgColor: watchLayout.innerColorDark)!
        majorTickColorPickerDark.color = NSColor(cgColor: watchLayout.majorTickColorDark)!
        minorTickColorPickerDark.color = NSColor(cgColor: watchLayout.minorTickColorDark)!
        textColorPickerDark.color = NSColor(cgColor: watchLayout.fontColorDark)!
        oddStermTickColorPickerDark.color = NSColor(cgColor: watchLayout.oddSolarTermTickColorDark)!
        evenStermTickColorPickerDark.color = NSColor(cgColor: watchLayout.evenSolarTermTickColorDark)!
        mercuryIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[0])!
        venusIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[1])!
        marsIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[2])!
        jupyterIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[3])!
        saturnIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[4])!
        moonIndicatorColorPicker.color = NSColor(cgColor: watchLayout.planetIndicator[5])!
        eclipseIndicatorColorPicker.color = NSColor(cgColor: watchLayout.eclipseIndicator)!
        fullmoonIndicatorColorPicker.color = NSColor(cgColor: watchLayout.fullmoonIndicator)!
        oddStermIndicatorColorPicker.color = NSColor(cgColor: watchLayout.oddStermIndicator)!
        evenStermIndicatorColorPicker.color = NSColor(cgColor: watchLayout.evenStermIndicator)!
        midnightIndicatorColorPicker.color = NSColor(cgColor: watchLayout.sunPositionIndicator[0])!
        sunriseIndicatorColorPicker.color = NSColor(cgColor: watchLayout.sunPositionIndicator[1])!
        noonIndicatorColorPicker.color = NSColor(cgColor: watchLayout.sunPositionIndicator[2])!
        sunsetIndicatorColorPicker.color = NSColor(cgColor: watchLayout.sunPositionIndicator[3])!
        moonriseIndicatorColorPicker.color = NSColor(cgColor: watchLayout.moonPositionIndicator[0])!
        moonmeridianIndicatorColorPicker.color = NSColor(cgColor: watchLayout.moonPositionIndicator[1])!
        moonsetIndicatorColorPicker.color = NSColor(cgColor: watchLayout.moonPositionIndicator[2])!
        populateFontFamilies(textFontFamilyPicker)
        textFontFamilyPicker.selectItem(withTitle: watchLayout.textFont.familyName!)
        populateFontMember(textFontTraitPicker, inFamily: textFontFamilyPicker)
        if let traits = watchLayout.textFont.fontName.split(separator: "-").last {
            textFontTraitPicker.selectItem(withTitle: String(traits))
            if textFontTraitPicker.selectedItem == nil {
                textFontTraitPicker.selectItem(at: 0)
            }
        }
        populateFontFamilies(centerTextFontFamilyPicker)
        centerTextFontFamilyPicker.selectItem(withTitle: watchLayout.centerFont.familyName!)
        populateFontMember(centerTextFontTraitPicker, inFamily: centerTextFontFamilyPicker)
        if let traits = watchLayout.centerFont.fontName.split(separator: "-").last {
            centerTextFontTraitPicker.selectItem(withTitle: String(traits))
            if centerTextFontTraitPicker.selectedItem == nil {
                centerTextFontTraitPicker.selectItem(at: 0)
            }
        }
        widthPicker.stringValue = "\(watchLayout.watchSize.width)"
        heightPicker.stringValue = "\(watchLayout.watchSize.height)"
        cornerRadiusRatioPicker.stringValue = "\(watchLayout.cornerRadiusRatio)"
        centerTextOffsetPicker.stringValue = "\(watchLayout.centerTextOffset)"
        textHorizontalOffsetPicker.stringValue = "\(watchLayout.horizontalTextOffset)"
        textVerticalOffsetPicker.stringValue = "\(watchLayout.verticalTextOffset)"
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.delegate = self
        guard let watchFace = WatchFace.currentInstance else { return }
        if LocationManager.shared.location != nil {
            currentLocationToggle.state = .on
        } else {
            currentLocationToggle.state = .off
        }
        currentLocationToggled(currentLocationToggle!)
        if let window = view.window {
            let screen = watchFace.getCurrentScreen()
            if watchFace.frame.maxX + 10 + window.frame.width < screen.maxX {
                window.setFrameOrigin(NSMakePoint(watchFace.frame.maxX + 10, watchFace.frame.midY - window.frame.height / 2))
            } else {
                window.setFrameOrigin(NSMakePoint(max(watchFace.frame.minX - 10 - window.frame.width, screen.minX), watchFace.frame.midY - window.frame.height / 2))
            }
        }
    }

    override func viewDidLoad() {
        Self.currentInstance = self
        super.viewDidLoad()
        updateUI()
        scrollToTop()
    }
    
    override func viewDidDisappear() {
        Self.currentInstance = nil
        NSColorPanel.shared.showsAlpha = false
        NSColorPanel.shared.setTarget(nil)
        NSColorPanel.shared.setAction(nil)
        NSColorPanel.shared.close()
        super.viewDidDisappear()
    }
}

final class FlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

final class ClickableStackView: NSStackView {
    func didTapHeading() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            guard let card = self.superview as? NSStackView else { return }
            var showOrHide = false
            for view in card.arrangedSubviews {
                if !(view === self) {
                    view.isHidden.toggle()
                    showOrHide = view.isHidden
                }
            }
            if let arrow = self.arrangedSubviews.last as? NSImageView {
                if showOrHide {
                    arrow.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Expand")
                } else {
                    arrow.image = NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Expand")
                }
            }
            card.superview?.superview?.superview?.layoutSubtreeIfNeeded()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        didTapHeading()
        super.mouseUp(with: event)
    }
}

final class CardStackView: NSStackView {
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        if effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            layer?.backgroundColor = NSColor(white: 0.1, alpha: 1).cgColor
        } else {
            layer?.backgroundColor = NSColor.white.cgColor
        }
    }
}

final class HelpViewController: NSViewController {
    static var currentInstance: HelpViewController?
    private let parser = MarkdownParser()
    @IBOutlet var stackView: NSStackView!
    @IBOutlet var contentView: NSView!
    
    func boldText(line: String, fontSize: CGFloat) -> NSAttributedString {
        let boldRanges = line.boldRanges
        let attrStr = NSMutableAttributedString()
        if !boldRanges.isEmpty {
            var boldRangesIndex = boldRanges.startIndex
            var startIndex = line.startIndex
            while boldRangesIndex < boldRanges.endIndex {
                let boldRange = boldRanges[boldRangesIndex]
                let plainText = line[startIndex..<line.index(boldRange.lowerBound, offsetBy: -2)]
                attrStr.append(NSAttributedString(string: String(plainText), attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
                startIndex = line.index(boldRange.upperBound, offsetBy: 2)
                let boldSubtext = line[boldRange]
                attrStr.append(NSAttributedString(string: String(boldSubtext), attributes: [.font: NSFont.boldSystemFont(ofSize: fontSize)]))
                boldRangesIndex = boldRanges.index(after: boldRangesIndex)
            }
            let remainingText = line[startIndex...]
            attrStr.append(NSAttributedString(string: String(remainingText), attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
        } else {
            let text = line.trimmingCharacters(in: .whitespaces)
            attrStr.append(NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: fontSize)]))
        }
        let paragraphStype = NSMutableParagraphStyle()
        paragraphStype.lineSpacing = 1.4
        paragraphStype.paragraphSpacingBefore = 10
        paragraphStype.paragraphSpacing = 0
        attrStr.addAttribute(.paragraphStyle, value: paragraphStype, range: NSMakeRange(0, attrStr.length))
        return attrStr
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Self.currentInstance = self
        
        stackView.spacing = 16
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.edgeInsets = NSEdgeInsetsMake(16, 15, 15, 0)
        
        let elements = parser.parse(helpString)

        for i in 0..<elements.count {
            let element = elements[i]
            
            switch element {
            case .heading(_, let text):
                let card: CardStackView = {
                    let stackView = CardStackView()
                    stackView.orientation = .vertical
                    stackView.alignment = .leading
                    stackView.distribution = .fill
                    stackView.spacing = 10
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    stackView.wantsLayer = true
                    stackView.layer?.cornerRadius = 10
                    stackView.layer?.cornerCurve = .continuous
                    stackView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
                    stackView.layer?.borderColor = NSColor(white: 0.5, alpha: 0.3).cgColor
                    stackView.layer?.borderWidth = 0.5
                    stackView.edgeInsets = NSEdgeInsetsMake(15, 10, 15, 10)
                    return stackView
                }()
                
                let row: ClickableStackView = {
                    let stackView = ClickableStackView()
                    stackView.orientation = .horizontal
                    stackView.alignment = .top
                    stackView.distribution = .equalCentering
                    stackView.spacing = 0
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    stackView.edgeInsets = NSEdgeInsetsMake(0, 0, 0, 0)
                    return stackView
                }()
                
                let titleLabel = {
                    let label = NSTextField(labelWithAttributedString: boldText(line: text, fontSize: NSFont.systemFontSize(for: .large)))
                    return label
                }()
                
                let collapseIndicator = {
                    let arrow = NSImageView()
                    arrow.alignment = .center
                    arrow.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Expand")
                    arrow.contentTintColor = NSColor.secondaryLabelColor
                    NSLayoutConstraint.activate([arrow.widthAnchor.constraint(equalToConstant: NSFont.systemFontSize),
                                                 arrow.heightAnchor.constraint(equalToConstant: NSFont.systemFontSize)])
                    return arrow
                }()

                row.addArrangedSubview(titleLabel)
                row.addArrangedSubview(collapseIndicator)
                card.addArrangedSubview(row)
                NSLayoutConstraint.activate([titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -NSFont.systemFontSize - 20)])
                stackView.addArrangedSubview(card)
                
            case .paragraph(text: let text):
                let label = NSTextField(labelWithAttributedString: boldText(line: text, fontSize: NSFont.systemFontSize(for: .regular)))
                label.isHidden = true
                if let card = stackView.arrangedSubviews.last as? NSStackView {
                    card.addArrangedSubview(label)
                    NSLayoutConstraint.activate([
                        label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: NSFont.systemFontSize(for: .regular)),
                        label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -NSFont.systemFontSize(for: .regular))
                    ])
                }
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let window = view.window, let watchFace = WatchFace.currentInstance {
            let screen = watchFace.getCurrentScreen()
            if watchFace.frame.minX - 10 - window.frame.width > screen.minX {
                window.setFrameOrigin(NSMakePoint(watchFace.frame.minX - 10 - window.frame.width, watchFace.frame.midY - window.frame.height / 2))
            } else {
                window.setFrameOrigin(NSMakePoint(min(watchFace.frame.maxX + 10, screen.maxX - window.frame.width), watchFace.frame.midY - window.frame.height / 2))
            }
        }
    }
    
    override func viewDidDisappear() {
        Self.currentInstance = nil
        super.viewDidDisappear()
    }
}

final class ThemesListViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet var tableView: NSTableView!
    
    var themes: [DataContainer.SavedTheme] = []
    let currentDeviceName = DataContainer.shared.deviceName
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("刪主題", comment: "Confirm to delete theme title"), action: #selector(tableViewEditItemClicked(_:)), keyEquivalent: "\u{08}"))
        tableView.menu = menu
        
        loadThemes()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.minSize = NSSize(width: 450, height: 300)
        view.window?.maxSize = NSSize(width: 480, height: 350)
    }
    
    @IBAction func refreshButtonClicked(_ sender: NSButton) {
        refresh()
    }

    @IBAction func dismissView(_ sender: NSButton) {
        dismiss(nil)
    }

    @IBAction func readFile(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.level = NSWindow.Level.floating
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.text, .yaml]
        panel.title = NSLocalizedString("Select Layout File", comment: "Open File")
        panel.message = NSLocalizedString("Choose a layout file to load from", comment: "Warning")
        panel.begin { [self]
            result in
            if result == .OK, let file = panel.url {
                do {
                    let content = try String(contentsOf: file)
                    let name = file.lastPathComponent
                    let nameRange = try NSRegularExpression(pattern: "^([^\\.]+)\\.?.*$").firstMatch(in: name, range: NSMakeRange(0, name.utf16.count))!.range(at: 1)
                    DataContainer.shared.saveLayout(content, name: self.generateNewName(baseName: (name as NSString).substring(with: nameRange)))
                    self.refresh()
                    self.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Load Failed", comment: "Load Failed")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.beginSheetModal(for: view.window!)
                }
            }
        }
    }

    @IBAction func writeFile(_ sender: Any) {
        let row = tableView.selectedRow
        if row >= 0 && row < themes.count {
            let theme = themes[row]
            let panel = NSSavePanel()
            panel.level = NSWindow.Level.floating
            panel.title = NSLocalizedString("Select Location", comment: "Save File")
            panel.nameFieldStringValue = "\(theme.name).txt"
            panel.begin { [self]
                result in
                if result == .OK, let file = panel.url {
                    do {
                        if let layout = DataContainer.shared.readSave(name: theme.name, deviceName: theme.deviceName) {
                            try layout.data(using: .utf8)?.write(to: file, options: .atomicWrite)
                        }
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Save Failed", comment: "Save Failed")
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .critical
                        alert.beginSheetModal(for: view.window!)
                    }
                }
            }
        } else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("選定主題先", comment: "No selection when exporting")
            alert.alertStyle = .warning
            alert.beginSheetModal(for: view.window!)
        }
    }

    @IBAction func deleteTheme(_ sender: NSButton) {
        tableViewEditItemClicked(sender)
    }

    @IBAction func addNew(_ sender: NSButton) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        tableView.beginUpdates()
        tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
        tableView.endUpdates()
        
        let themeNameView = tableView.view(atColumn: 0, row: 0, makeIfNecessary: false) as! NSTableCellView
        themeNameView.textField?.target = self
        themeNameView.textField?.action = #selector(preventDeselect(_:))
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        tableView.editColumn(0, row: 0, with: nil, select: true)
        let modifiedDateView = tableView.view(atColumn: 2, row: 0, makeIfNecessary: false) as! NSTableCellView
        modifiedDateView.textField?.stringValue = timeFormatter.string(from: Date())
        let deviceNameView = tableView.view(atColumn: 1, row: 0, makeIfNecessary: false) as! NSTableCellView
        deviceNameView.textField?.stringValue = currentDeviceName
        
        let fileName = generateNewName(baseName: NSLocalizedString("無名", comment: "new theme default name"))
        themeNameView.textField?.stringValue = fileName
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            themeNameView.textField?.action = #selector(self.newTheme(_:))
        }
    }

    func generateNewName(baseName: String) -> String {
        var newFileName = baseName
        let currentDeviceThemes = themes.filter { $0.deviceName == self.currentDeviceName }.map { $0.name }
        var i = 2
        while currentDeviceThemes.contains(newFileName) {
            newFileName = baseName + " \(i)"
            i += 1
        }
        return newFileName
    }
    
    @objc func preventDeselect(_ sender: NSTextField) {
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        tableView.editColumn(0, row: 0, with: nil, select: true)
    }
    
    @objc func refresh() {
        loadThemes()
        tableView.reloadData()
    }
    
    func loadThemes() {
        var loadedThemes = DataContainer.shared.listAll()
        loadedThemes.sort { left, right in
            if left.deviceName == currentDeviceName && right.deviceName == currentDeviceName {
                return left.modifiedDate > right.modifiedDate
            } else if left.deviceName == currentDeviceName {
                return true
            } else if right.deviceName == currentDeviceName {
                return false
            } else {
                if left.deviceName != right.deviceName {
                    return left.deviceName > right.deviceName
                } else {
                    return left.modifiedDate > right.modifiedDate
                }
            }
        }
        themes = loadedThemes
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return themes.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < themes.count else { return nil }
        let theme = themes[row]
        let cell: NSTableCellView
        switch tableColumn {
        case tableView.tableColumns[0]:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NameCell"), owner: nil) as! NSTableCellView
            cell.textField?.stringValue = theme.name
            cell.textField?.isEditable = true
            cell.textField?.target = self
            cell.textField?.action = #selector(renameTheme(_:))
        case tableView.tableColumns[1]:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeviceNameCell"), owner: nil) as! NSTableCellView
            cell.textField?.stringValue = theme.deviceName
            cell.textField?.isEditable = false
        case tableView.tableColumns[2]:
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DateCell"), owner: nil) as! NSTableCellView
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            
            if dateFormatter.string(from: theme.modifiedDate) == dateFormatter.string(from: Date()) {
                cell.textField?.stringValue = timeFormatter.string(from: theme.modifiedDate)
            } else {
                cell.textField?.stringValue = dateFormatter.string(from: theme.modifiedDate)
            }
            cell.textField?.textColor = .secondaryLabelColor
            cell.textField?.isEditable = false
        default:
            return nil
        }
        return cell
    }
    
    @objc func renameTheme(_ sender: NSTextField) {
        let fileName = sender.stringValue
        let row = tableView.selectedRow
        guard row >= 0 && row < themes.count else { return }
        let theme = themes[row]
        
        if fileName != "" {
            let currentDeviceThemes = themes.filter { $0.deviceName == self.currentDeviceName }
            if !(currentDeviceThemes.map { $0.name }.contains(fileName)) {
                DataContainer.shared.renameSave(name: theme.name, deviceName: theme.deviceName, newName: fileName)
                refresh()
                return
            }
        }
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("易名", comment: "rename")
        alert.informativeText = NSLocalizedString("不得爲空，不得重名", comment: "no blank, no duplicate name")
        alert.addButton(withTitle: NSLocalizedString("作罷", comment: "Ok"))
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window!)
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        tableView.editColumn(0, row: row, with: nil, select: true)
    }
    
    @objc func newTheme(_ sender: NSTextField) {
        let fileName = sender.stringValue
        if fileName != "" {
            let currentDeviceThemes = themes.filter { $0.deviceName == self.currentDeviceName }
            if !(currentDeviceThemes.map { $0.name }.contains(fileName)) {
                DataContainer.shared.saveLayout(WatchLayout.shared.encode(), name: fileName)
                refresh()
                return
            }
        }
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("取名", comment: "set a name")
        alert.informativeText = NSLocalizedString("不得爲空，不得重名", comment: "no blank, no duplicate name")
        alert.addButton(withTitle: NSLocalizedString("作罷", comment: "Ok"))
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window!)
    }
    
    @objc func tableViewDoubleClick(_ sender: Any) {
        let row = tableView.selectedRow
        let theme = themes[row]
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("換主題", comment: "Confirm to select theme title")
        alert.informativeText = NSLocalizedString("換爲：", comment: "Confirm to select theme message") + theme.name
        alert.addButton(withTitle: NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"))
        alert.addButton(withTitle: NSLocalizedString("容吾三思", comment: "Cancel Resetting Settings"))
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                DataContainer.shared.loadSave(name: theme.name, deviceName: theme.deviceName)
                WatchFace.currentInstance?.invalidateShadow()
                WatchFace.currentInstance?.updateSize()
                WatchFace.currentInstance?._view.drawView(forceRefresh: true)
                if let parentView = ConfigurationViewController.currentInstance {
                    parentView.updateUI()
                }
            }
        }
    }
    
    @objc func tableViewEditItemClicked(_ sender: Any?) {
        let row = tableView.selectedRow
        guard row >= 0 && row < themes.count else { return }
        let theme = themes[row]
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("刪主題", comment: "Confirm to delete theme title")
        alert.informativeText = NSLocalizedString("刪：", comment: "Confirm to delete theme message") + theme.name
        alert.addButton(withTitle: NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"))
        alert.addButton(withTitle: NSLocalizedString("容吾三思", comment: "Cancel Resetting Settings"))
        alert.alertStyle = .warning
        alert.beginSheetModal(for: view.window!) { [self] response in
            if response == .alertFirstButtonReturn {
                DataContainer.shared.deleteSave(name: theme.name, deviceName: theme.deviceName)
                refresh()
            }
        }
    }
}
    
