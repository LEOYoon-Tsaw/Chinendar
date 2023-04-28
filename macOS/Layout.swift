//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import AppKit

class WatchLayout: MetaWatchLayout {
    var textFont: NSFont
    var centerFont: NSFont
    override init() {
        textFont = NSFont.userFont(ofSize: NSFont.systemFontSize)!
        centerFont = NSFontManager.shared.font(withFamily: NSFont.userFont(ofSize: NSFont.systemFontSize)!.familyName!,
                                               traits: .boldFontMask, weight: 900, size: NSFont.systemFontSize)!
        super.init()
    }
    override func encode() -> String {
        var encoded = super.encode()
        encoded += "textFont: \(textFont.fontName)\n"
        encoded += "centerFont: \(centerFont.fontName)\n"
        return encoded
    }
    override func update(from values: Dictionary<String, String>) {
        super.update(from: values)
        if let name = values["textFont"] {
            textFont = NSFont(name: name, size: NSFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = NSFont(name: name, size: NSFont.systemFontSize) ?? centerFont
        }
    }
}

class ColorWell: NSColorWell {
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        NSColorPanel.shared.showsAlpha = true
        super.mouseDown(with: event)
    }
    override func resignFirstResponder() -> Bool {
        NSColorPanel.shared.close()
        return super.resignFirstResponder()
    }
}

class ConfigurationViewController: NSViewController, NSWindowDelegate {
    static var currentInstance: ConfigurationViewController? = nil
    @IBOutlet weak var readLayout: NSButton!
    @IBOutlet weak var writeLayout: NSButton!
    @IBOutlet weak var globalMonthPicker: NSPopUpButton!
    @IBOutlet weak var apparentTimePicker: NSPopUpButton!
    @IBOutlet weak var datetimePicker: NSDatePicker!
    @IBOutlet weak var currentTimeToggle: NSButton!
    @IBOutlet weak var timezonePicker: NSPopUpButton!
    @IBOutlet weak var latitudeDegreePicker: NSTextField!
    @IBOutlet weak var latitudeMinutePicker: NSTextField!
    @IBOutlet weak var latitudeSecondPicker: NSTextField!
    @IBOutlet weak var latitudeSpherePicker: NSSegmentedControl!
    @IBOutlet weak var longitudeDegreePicker: NSTextField!
    @IBOutlet weak var longitudeMinutePicker: NSTextField!
    @IBOutlet weak var longitudeSecondPicker: NSTextField!
    @IBOutlet weak var longitudeSpherePicker: NSSegmentedControl!
    @IBOutlet weak var currentLocationToggle: NSButton!
    @IBOutlet weak var firstRingGradientPicker: GradientSlider!
    @IBOutlet weak var secondRingGradientPicker: GradientSlider!
    @IBOutlet weak var thirdRingGradientPicker: GradientSlider!
    @IBOutlet weak var shadeAlphaValuePicker: NSSlider!
    @IBOutlet weak var shadeAlphaValueLabel: NSTextField!
    @IBOutlet weak var firstRingIsLoop: NSButton!
    @IBOutlet weak var secondRingIsLoop: NSButton!
    @IBOutlet weak var thirdRingIsLoop: NSButton!
    @IBOutlet weak var innerTextGradientPicker: GradientSlider!
    @IBOutlet weak var backAlphaValuePicker: NSSlider!
    @IBOutlet weak var backAlphaValueLabel: NSTextField!
    @IBOutlet weak var minorTickAlphaValuePicker: NSSlider!
    @IBOutlet weak var minorTickAlphaValueLabel: NSTextField!
    @IBOutlet weak var majorTickAlphaValuePicker: NSSlider!
    @IBOutlet weak var majorTickAlphaValueLabel: NSTextField!
    @IBOutlet weak var innerColorPicker: NSColorWell!
    @IBOutlet weak var majorTickColorPicker: NSColorWell!
    @IBOutlet weak var minorTickColorPicker: NSColorWell!
    @IBOutlet weak var textColorPicker: NSColorWell!
    @IBOutlet weak var oddStermTickColorPicker: NSColorWell!
    @IBOutlet weak var evenStermTickColorPicker: NSColorWell!
    @IBOutlet weak var innerColorPickerDark: NSColorWell!
    @IBOutlet weak var majorTickColorPickerDark: NSColorWell!
    @IBOutlet weak var minorTickColorPickerDark: NSColorWell!
    @IBOutlet weak var textColorPickerDark: NSColorWell!
    @IBOutlet weak var oddStermTickColorPickerDark: NSColorWell!
    @IBOutlet weak var evenStermTickColorPickerDark: NSColorWell!
    @IBOutlet weak var mercuryIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var venusIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var marsIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var jupyterIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var saturnIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var eclipseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var fullmoonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var oddStermIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var evenStermIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var sunriseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var sunsetIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var noonIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var midnightIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonriseIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonsetIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var moonmeridianIndicatorColorPicker: NSColorWell!
    @IBOutlet weak var textFontFamilyPicker: NSPopUpButton!
    @IBOutlet weak var textFontTraitPicker: NSPopUpButton!
    @IBOutlet weak var centerTextFontFamilyPicker: NSPopUpButton!
    @IBOutlet weak var centerTextFontTraitPicker: NSPopUpButton!
    @IBOutlet weak var widthPicker: NSTextField!
    @IBOutlet weak var heightPicker: NSTextField!
    @IBOutlet weak var cornerRadiusRatioPicker: NSTextField!
    @IBOutlet weak var centerTextOffsetPicker: NSTextField!
    @IBOutlet weak var textHorizontalOffsetPicker: NSTextField!
    @IBOutlet weak var textVerticalOffsetPicker: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var revertButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var contentView: NSView!
    
    var panelTimezone = TimeZone.init(secondsFromGMT: 0)!
    
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
    func clearFontMember(_ picker: NSPopUpButton) {
        picker.removeAllItems()
    }
    func readFont(family: NSPopUpButton, style: NSPopUpButton) -> NSFont? {
        let size = NSFont.systemFontSize
        let fontFamily: String = family.titleOfSelectedItem!
        let fontTraits: String = style.titleOfSelectedItem!
        if let font = NSFont(name: "\(fontFamily.filter {!$0.isWhitespace})-\(fontTraits.filter {!$0.isWhitespace})", size: size) {
            return font
        }
        let members = NSFontManager.shared.availableMembers(ofFontFamily: fontFamily) ?? [[Any]]()
        for i in 0..<members.count {
            if let memberName = members[i][1] as? String, memberName == fontTraits,
                let weight = members[i][2] as? Int,
                let traits = members[i][3] as? UInt {
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
            longitudeSpherePicker.isEnabled = true
            longitudeDegreePicker.isEnabled = true
            longitudeMinutePicker.isEnabled = true
            longitudeSecondPicker.isEnabled = true
            latitudeSpherePicker.isEnabled = true
            latitudeDegreePicker.isEnabled = true
            latitudeMinutePicker.isEnabled = true
            latitudeSecondPicker.isEnabled = true
        } else {
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
    
    @IBAction func currentTimeToggled(_ sender: Any) {
        view.window?.makeFirstResponder(datetimePicker)
        datetimePicker.isEnabled = !readToggle(button: currentTimeToggle)
        if !datetimePicker.isEnabled {
            timezonePicker.selectItem(withTitle: Calendar.current.timeZone.identifier)
        }
    }
    @IBAction func currentLocationToggled(_ sender: Any) {
        if readToggle(button: currentLocationToggle) {
            if Chinese_Time.locManager?.authorizationStatus == .authorized || Chinese_Time.locManager?.authorizationStatus == .authorizedAlways {
                turnLocation(on: false)
                if let sender = sender as? NSButton, sender == currentLocationToggle {
                    Chinese_Time.locManager!.startUpdatingLocation()
                }
            } else if Chinese_Time.locManager?.authorizationStatus == .notDetermined || Chinese_Time.locManager?.authorizationStatus == .restricted {
                Chinese_Time.locManager!.requestWhenInUseAuthorization()
                currentLocationToggle.state = .off
            } else {
                currentLocationToggle.state = .off
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("定位被禁用", comment: "Location service disabled")
                alert.informativeText = NSLocalizedString("若欲定位請先打開定位許可", comment: "Please enable location service to obtain your longitude and latitude")
                alert.runModal()
            }
        } else {
            turnLocation(on: true)
        }
    }
    @IBAction func clearLocation(_ sender: NSButton) {
        if longitudeSecondPicker.isEnabled {
            longitudeDegreePicker.doubleValue = 0
            longitudeMinutePicker.doubleValue = 0
            longitudeSecondPicker.doubleValue = 0
            longitudeSpherePicker.selectedSegment = -1
        }
        if latitudeSpherePicker.isEnabled {
            latitudeDegreePicker.doubleValue = 0
            latitudeMinutePicker.doubleValue = 0
            latitudeSecondPicker.doubleValue = 0
            latitudeSpherePicker.selectedSegment = -1
        }
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
    @IBAction func backAlphaPickerChanged(_ sender: Any) {
        view.window?.makeFirstResponder(backAlphaValuePicker)
        backAlphaValueLabel.stringValue = String(format: "%1.2f", backAlphaValuePicker.doubleValue)
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
    @IBAction func cancel(_ sender: Any) {
        self.view.window?.close()
    }
    @IBAction func revert(_ sender: Any) {
        view.window?.makeFirstResponder(revertButton)
        if let watchFace = WatchFace.currentInstance, let temp = WatchFaceView.layoutTemplate {
            watchFace._view.watchLayout.update(from: temp)
            watchFace.updateSize(with: watchFace.frame)
            watchFace._view.drawView(forceRefresh: true)
            updateUI()
        }
    }
    @IBAction func apply(_ sender: Any) {
        updateData()
        if let watchFace = WatchFace.currentInstance {
            watchFace.invalidateShadow()
            watchFace.updateSize(with: watchFace.frame)
            watchFace._view.drawView(forceRefresh: true)
        }
        updateUI()
    }
    @IBAction func ok(_ sender: Any) {
        apply(sender)
        guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
        WatchFaceView.layoutTemplate = delegate.saveLayout()
        self.view.window?.close()
    }
    @IBAction func readFile(_ sender: Any) {
        (NSApp.delegate as! AppDelegate).openFile(sender)
    }
    @IBAction func writeFile(_ sender: Any) {
        (NSApp.delegate as! AppDelegate).saveFile(sender)
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
        let watchLayout = watchView.watchLayout
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
        if latitudeSpherePicker.selectedSegment == -1 || longitudeSpherePicker.selectedSegment == -1 {
            watchView.location = nil
        } else {
            var latitude = latitudeDegreePicker.doubleValue
            latitude += latitudeMinutePicker.doubleValue / 60
            latitude += latitudeSecondPicker.doubleValue / 3600
            latitude *= latitudeSpherePicker.selectedSegment == 0 ? 1 : -1
            
            var longitude = longitudeDegreePicker.doubleValue
            longitude += longitudeMinutePicker.doubleValue / 60
            longitude += longitudeSecondPicker.doubleValue / 3600
            longitude *= longitudeSpherePicker.selectedSegment == 0 ? 1 : -1
            watchView.location = NSMakePoint(latitude, longitude)
        }
        
        watchLayout.firstRing = firstRingGradientPicker.gradient
        watchLayout.secondRing = secondRingGradientPicker.gradient
        watchLayout.thirdRing = thirdRingGradientPicker.gradient
        watchLayout.shadeAlpha = shadeAlphaValuePicker.doubleValue
        watchLayout.centerFontColor = innerTextGradientPicker.gradient
        watchLayout.backAlpha = backAlphaValuePicker.doubleValue
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
    
    func updateUI() {
        let watchView = WatchFace.currentInstance!._view
        let watchLayout = watchView.watchLayout
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
        if let location = watchView.location {
            var latitude = location.x
            latitudeSpherePicker.selectSegment(withTag: latitude >= 0 ? 0 : 1)
            latitude = abs(latitude)
            latitudeDegreePicker.doubleValue = floor(latitude)
            latitude = (latitude - floor(latitude)) * 60
            latitudeMinutePicker.doubleValue = floor(latitude)
            latitude = (latitude - floor(latitude)) * 60
            latitudeSecondPicker.doubleValue = latitude
            
            var longitude = location.y
            longitudeSpherePicker.selectSegment(withTag: longitude >= 0 ? 0 : 1)
            longitude = abs(longitude)
            longitudeDegreePicker.doubleValue = floor(longitude)
            longitude = (longitude - floor(longitude)) * 60
            longitudeMinutePicker.doubleValue = floor(longitude)
            longitude = (longitude - floor(longitude)) * 60
            longitudeSecondPicker.doubleValue = longitude
            
            currentLocationToggled(0)
            
            apparentTimePicker.isEnabled = true
            apparentTimePicker.selectItem(at: ChineseCalendar.apparentTime ? 1 : 0)
        } else {
            apparentTimePicker.isEnabled = false
            apparentTimePicker.selectItem(at: 0)
        }

        firstRingGradientPicker.gradient = watchLayout.firstRing
        secondRingGradientPicker.gradient = watchLayout.secondRing
        thirdRingGradientPicker.gradient = watchLayout.thirdRing
        toggle(button: firstRingIsLoop, with: watchLayout.firstRing.isLoop)
        toggle(button: secondRingIsLoop, with: watchLayout.secondRing.isLoop)
        toggle(button: thirdRingIsLoop, with: watchLayout.thirdRing.isLoop)
        shadeAlphaValuePicker.doubleValue = Double(watchLayout.shadeAlpha)
        shadeAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.shadeAlpha)
        innerTextGradientPicker.gradient = watchLayout.centerFontColor
        backAlphaValuePicker.doubleValue = Double(watchLayout.backAlpha)
        backAlphaValueLabel.stringValue = String(format: "%1.2f", watchLayout.backAlpha)
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
        self.view.window?.delegate = self
        if Chinese_Time.locManager?.authorizationStatus == .authorized || Chinese_Time.locManager?.authorizationStatus == .authorizedAlways {
            currentLocationToggle.state = .on
        } else {
            currentLocationToggle.state = .off
        }
        currentLocationToggled(currentLocationToggle!)
        if let window = self.view.window, let watchFace = WatchFace.currentInstance {
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
    }
}

class GradientSlider: NSControl, NSColorChanging {
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
        get {
            return true
        }
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
        self.window?.makeFirstResponder(self)
        previousLocation = event.locationInWindow
        previousLocation = self.convert(previousLocation!, from: window?.contentView)
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
            let color = self.gradient.interpolate(at: newValue)
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
            location = self.convert(location, from: window?.contentView)
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
