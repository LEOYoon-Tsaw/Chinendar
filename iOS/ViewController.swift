//
//  ViewController.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/17/23.
//

import UIKit

func coordinateDesp(coordinate: CGPoint) -> (String, String) {
    var latitudeLabel = ""
    if coordinate.x > 0 {
        latitudeLabel = "N"
    } else if coordinate.x < 0 {
        latitudeLabel = "S"
    }
    let latitude = Int(round(abs(coordinate.x) * 3600))
    let latitudeString = "\(latitude / 3600)°\((latitude % 3600) / 60)\'\(latitude % 60)\" \(latitudeLabel)"
    
    var longitudeLabel = ""
    if coordinate.y > 0 {
        longitudeLabel = "E"
    } else if coordinate.y < 0 {
        longitudeLabel = "W"
    }
    let longitude = Int(round(abs(coordinate.y) * 3600))
    let longitudeString = "\(longitude / 3600)°\((longitude % 3600) / 60)\'\(longitude % 60)\" \(longitudeLabel)"
    
    return (latitudeString, longitudeString)
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var watchFace: WatchFaceView!
    
    func newSize(frame: CGSize, idealSize: CGSize) -> CGSize {
        let height: CGFloat
        let width: CGFloat
        if frame.width > frame.height {
            height = min(frame.height, idealSize.width)
            width = min(idealSize.height / idealSize.width * height, frame.width * 0.8)
        } else {
            width = min(frame.width, idealSize.width)
            height = min(idealSize.height / idealSize.width * width, frame.height * 0.8)
        }
        return CGSize(width: width, height: height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let screen = UIScreen.main.bounds
        let newSize = newSize(frame: screen.size, idealSize: watchFace.watchLayout.watchSize)
        watchFace.frame = CGRect(x: (screen.width - newSize.width) / 2.0, y: (screen.height - newSize.height) / 2.0,
                                  width: newSize.width, height: newSize.height)
        watchFace.setAutoRefresh()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        watchFace!.addGestureRecognizer(longPressGesture)

        // Do any additional setup after loading the view.
    }
    
    @objc func longPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "Settings") as! UINavigationController
            self.present(settingsViewController, animated:true, completion:nil)
            UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let screen = UIScreen.main.bounds
        let newSize = newSize(frame: screen.size, idealSize: watchFace!.watchLayout.watchSize)
        watchFace!.updateSize(with: CGRect(x: (screen.width - newSize.width) / 2.0, y: (screen.height - newSize.height) / 2.0,
                                           width: newSize.width, height: newSize.height))
        super.traitCollectionDidChange(previousTraitCollection)
    }
}

class TableCell: UITableViewCell {
    static let identifier = "UITableViewCell"
    var title: String?
    var pushView: (() -> Void)?
    var desp1: String?
    var desp2: String?
    var elements = UIView()
    var segment: UISegmentedControl?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        elements.removeFromSuperview()
        segment?.removeFromSuperview()
        elements = UIView()
        
        let label = UILabel()
        let labelSize = CGSize(width: 100, height: 21)
        label.frame = CGRect(x: 15, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
        label.text = title
        elements.addSubview(label)
        
        if pushView != nil {
            let arrow = UIImageView(image: UIImage(systemName: "chevron.forward")!)
            let arrowSize = CGSize(width: 9, height: 12)
            arrow.frame = CGRect(x: bounds.width - arrowSize.width - 15, y: (bounds.height - arrowSize.height) / 2, width: arrowSize.width, height: arrowSize.height)
            arrow.tintColor = .systemGray
            elements.addSubview(arrow)
            
            if let desp1 = self.desp1, let desp2 = self.desp2 {
                let label1 = UILabel()
                label1.text = desp1
                label1.textColor = .secondaryLabel
                label1.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: bounds.height / 2 - labelSize.height - 2, width: CGRectGetMinX(arrow.frame) - CGRectGetMaxX(label.frame) - 30, height: labelSize.height)
                elements.addSubview(label1)
                let label2 = UILabel()
                label2.text = desp2
                label2.textColor = .secondaryLabel
                label2.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: bounds.height / 2 + 2, width: CGRectGetMinX(arrow.frame) - CGRectGetMaxX(label.frame) - 30, height: labelSize.height)
                elements.addSubview(label2)
            }
        } else if segment != nil {
                segment!.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: (bounds.height - labelSize.height * 1.6) / 2, width: bounds.width - CGRectGetMaxX(label.frame) - 30, height: labelSize.height * 1.6)
                self.addSubview(segment!)
        }
        self.addSubview(elements)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
        pushView = nil
        desp1 = nil
        desp2 = nil
        segment = nil
    }
}

struct DuelOption {
    let title: String
    let segment: UISegmentedControl
}
struct DetailOption {
    let title: String
    let action: (() -> Void)?
    let desp1: String?
    let desp2: String?
}
enum SettingsOption {
    case detail(model: DetailOption)
    case dual(model: DuelOption)
}
struct Section {
    let title: String
    let options: [SettingsOption]
}

class SettingsViewController: UITableViewController {
    var models = [Section]()
    
    func createNextView(name: String) -> (() -> Void) {
        func openView() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextView = storyboard.instantiateViewController(withIdentifier: name)
            navigationController?.pushViewController(nextView, animated: true)
        }
        return openView
    }
    
    @objc func globalMonthToggled(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            ChineseCalendar.globalMonth = true
        } else if segment.selectedSegmentIndex == 1 {
            ChineseCalendar.globalMonth = false
        }
        UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        WatchFaceView.currentInstance?.drawView(forceRefresh: false)
    }
    @objc func apparentTimeToggled(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            ChineseCalendar.apparentTime = true
        } else if segment.selectedSegmentIndex == 1 {
            ChineseCalendar.apparentTime = false
        }
        UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        WatchFaceView.currentInstance?.drawView(forceRefresh: false)
    }
    
    func fillData() {
        let time = WatchFaceView.currentInstance?.displayTime ?? Date()
        let timezone = WatchFaceView.currentInstance?.timezone ?? Calendar.current.timeZone
        let locationString = WatchFaceView.currentInstance?.location.map { coordinateDesp(coordinate: $0) }
        let datetime = DetailOption(title: "顯示時間", action: createNextView(name: "DateTime"),
                                    desp1: time.formatted(date: .abbreviated, time: .shortened), desp2: timezone.identifier)
        let location = DetailOption(title: "經緯度", action: createNextView(name: "Location"),
                                      desp1: locationString?.0, desp2: locationString?.1)
        
        let globalMonthSegment = UISegmentedControl(items: ["精確至時刻", "精確至日"])
        globalMonthSegment.selectedSegmentIndex = ChineseCalendar.globalMonth ? 0 : 1
        globalMonthSegment.addTarget(self, action: #selector(globalMonthToggled(segment:)), for: .allEvents)
        let leapMonth = DuelOption(title: "置閏法", segment: globalMonthSegment)
        
        let apparentTimeSegment = UISegmentedControl(items: ["真太陽時", "標準時"])
        apparentTimeSegment.selectedSegmentIndex = ChineseCalendar.apparentTime ? 0 : 1
        apparentTimeSegment.addTarget(self, action: #selector(apparentTimeToggled(segment:)), for: .allEvents)
        let apparantDay = DuelOption(title: "時間", segment: apparentTimeSegment)
        models = [
            Section(title: "數據", options: [.dual(model: leapMonth), .dual(model: apparantDay), .detail(model: datetime) , .detail(model: location)]),
            Section(title: "樣式", options: [.detail(model: DetailOption(title: "圈色", action: createNextView(name: "CircleColors"), desp1: nil, desp2: nil)),
                                           .detail(model: DetailOption(title: "塊標色", action: createNextView(name: "MarkColors"), desp1: nil, desp2: nil)),
                                            .detail(model: DetailOption(title: "佈局", action: createNextView(name: "Layouts"), desp1: nil, desp2: nil))])
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.register(TableCell.self, forCellReuseIdentifier: TableCell.identifier)
        tableView.rowHeight = 66
        fillData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].options.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return models[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = models[indexPath.section].options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TableCell.identifier, for: indexPath) as! TableCell
        switch option {
        case .detail(model: let model):
            cell.title = model.title
            cell.desp1 = model.desp1
            cell.desp2 = model.desp2
            cell.pushView = model.action
        case.dual(model: let model):
            cell.title = model.title
            cell.segment = model.segment
        }
        return cell
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = (tableView.cellForRow(at: indexPath) as! TableCell)
        if let action = cell.pushView {
            action()
        }
    }
}

class LocationView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    static var currentInstance: LocationView?
    
    @IBOutlet weak var longitudePicker: UIPickerView!
    @IBOutlet weak var latitudePicker: UIPickerView!
    @IBOutlet weak var display: UITextField!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var currentLocationSwitch: UISwitch!
    
    var longitude: [Int] = [0, 0, 0, 0]
    var latitude: [Int] = [0, 0, 0, 0]
    
    func makeSelection(value: Double, picker: UIPickerView) {
        var values = [0, 0, 0, 0]
        values[3] = value >= 0 ? 0 : 1
        picker.selectRow(values[3], inComponent: 3, animated: true)
        let tempValue = Int(round(abs(value) * 3600))
        values[0] = tempValue / 3600
        picker.selectRow(values[0], inComponent: 0, animated: true)
        values[1] = (tempValue % 3600) / 60
        picker.selectRow(values[1], inComponent: 1, animated: true)
        values[2] = tempValue % 60
        picker.selectRow(values[2], inComponent: 2, animated: true)
        if picker === longitudePicker {
            longitude = values
        } else if picker === latitudePicker {
            latitude = values
        }
    }
    
    func fillData() {
        if let location = WatchFaceView.currentInstance?.location {
            let locationString = coordinateDesp(coordinate: location)
            display.text = "\(locationString.0), \(locationString.1)"
            
            makeSelection(value: location.y, picker: longitudePicker)
            makeSelection(value: location.x, picker: latitudePicker)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "經緯度"
        navigationItem.largeTitleDisplayMode = .never
        contentView.layer.cornerRadius = 10
        longitudePicker.delegate = self
        longitudePicker.dataSource = self
        latitudePicker.delegate = self
        latitudePicker.dataSource = self
        Self.currentInstance = self
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        fillData()
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Self.currentInstance = nil
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 4
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === longitudePicker {
            let numbers = [0: 180, 1: 60, 2: 60, 3: 2]
            return numbers[component]!
        } else if pickerView === latitudePicker {
            let numbers = [0: 90, 1: 60, 2: 60, 3: 2]
            return numbers[component]!
        } else {
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0, 1, 2:
            return "\(row)"
        case 3:
            if pickerView === longitudePicker {
                return row == 0 ? "E" : "W"
            } else if pickerView === latitudePicker {
                return row == 0 ? "N" : "S"
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    func readCoordinate() -> CGPoint {
        var longitudeValue = Double(longitude[0])
        longitudeValue += Double(longitude[1]) / 60
        longitudeValue += Double(longitude[2]) / 3600
        longitudeValue *= longitude[3] == 0 ? 1.0 : -1.0
        var latitudeValue = Double(latitude[0])
        latitudeValue += Double(latitude[1]) / 60
        latitudeValue += Double(latitude[2]) / 3600
        latitudeValue *= latitude[3] == 0 ? 1.0 : -1.0
        return CGPoint(x: latitudeValue, y: longitudeValue)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === longitudePicker {
            longitude[component] = row
        } else if pickerView === latitudePicker {
            latitude[component] = row
        }
        let locationString = coordinateDesp(coordinate: readCoordinate())
        display.text = "\(locationString.0), \(locationString.1)"
        currentLocationSwitch.isOn = false
    }
    
    @IBAction func currentLocationToggled(_ sender: UISwitch) {
        if currentLocationSwitch.isOn {
            if Chinese_Time_iOS.locManager!.authorizationStatus == .authorizedAlways || Chinese_Time_iOS.locManager!.authorizationStatus == .authorizedWhenInUse {
                Chinese_Time_iOS.locManager!.startUpdatingLocation()
            } else {
                currentLocationSwitch.isOn = false
            }
        }
    }
}

class DateTimeView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var datetimePicker: UIDatePicker!
    @IBOutlet weak var timezonePicker: UIPickerView!
    @IBOutlet weak var currentTime: UISwitch!
    @IBOutlet weak var contentView: UIView!
    
    var timeZones = [String: [String]]()
    
    func populateTimezones() {
        let allTimezones = TimeZone.knownTimeZoneIdentifiers
        for timezone in allTimezones {
            let components = timezone.split(separator: "/")
            let region = String(components[0])
            if components.count > 1 {
                let city = String(components[1])
                if timeZones[region] != nil {
                    timeZones[region]!.append(city)
                } else {
                    timeZones[region] = [city]
                }
            } else {
                timeZones[region] = []
            }
        }
    }
    
    func selectTimezone(timezone: TimeZone) {
        let components = timezone.identifier.split(separator: "/")
        let regionIndex = timeZones.keys.firstIndex(of: String(components[0]))!
        timezonePicker.selectRow(timeZones.keys.distance(from: timeZones.keys.startIndex, to: regionIndex), inComponent: 0, animated: true)
        if components.count > 1 {
            timezonePicker.reloadComponent(1)
            let cityIndex = timeZones[timeZones.keys[regionIndex]]!.firstIndex(of: String(components[1]))!
            timezonePicker.selectRow(cityIndex, inComponent: 1, animated: true)
        }
    }
    
    func fillData() {
        var timezone = Calendar.current.timeZone
        if let date = WatchFaceView.currentInstance?.displayTime {
            datetimePicker.date = date
            timezone = WatchFaceView.currentInstance!.timezone
        }
        selectTimezone(timezone: timezone)
    }
    
    override func viewDidLoad() {
        populateTimezones()
        timezonePicker.delegate = self
        timezonePicker.dataSource = self
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        super.viewDidLoad()
        title = "顯示時間"
        navigationItem.largeTitleDisplayMode = .never
        contentView.layer.cornerRadius = 10
        datetimePicker.contentHorizontalAlignment = .center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fillData()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return timeZones.count
        } else if component == 1 {
            let region = pickerView.selectedRow(inComponent: 0)
            let index = timeZones.index(timeZones.startIndex, offsetBy: region)
            return timeZones[timeZones.keys[index]]?.count ?? 0
        } else {
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            let index = timeZones.index(timeZones.startIndex, offsetBy: row)
            return timeZones.keys[index]
        } else if component == 1 {
            let region = pickerView.selectedRow(inComponent: 0)
            let index = timeZones.index(timeZones.startIndex, offsetBy: region)
            let cities = timeZones[timeZones.keys[index]]
            return cities?[row]
        } else {
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            pickerView.reloadComponent(1)
        }
        currentTime.isOn = false
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        currentTime.isOn = false
    }
    @IBAction func currentDateToggled(_ sender: UISwitch) {
        if currentTime.isOn {
            WatchFaceView.currentInstance?.displayTime = nil
            datetimePicker.date = Date()
            selectTimezone(timezone: Calendar.current.timeZone)
        }
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
}

class CircleColorView: UIViewController {
    @IBOutlet weak var yearColor: GradientSlider!
    @IBOutlet weak var monthColor: GradientSlider!
    @IBOutlet weak var dayColor: GradientSlider!
    @IBOutlet weak var centerTextColor: GradientSlider!
    @IBOutlet weak var yearColorLoop: UISwitch!
    @IBOutlet weak var monthColorLoop: UISwitch!
    @IBOutlet weak var dayColorLoop: UISwitch!
    @IBOutlet weak var circleTransparancy: UISlider!
    @IBOutlet weak var backgroundTransparancy: UISlider!
    @IBOutlet weak var majorTickTransparancy: UISlider!
    @IBOutlet weak var minorTickTransparancy: UISlider!
    @IBOutlet weak var circleTransparancyReading: UILabel!
    @IBOutlet weak var backgroundTransparancyReading: UILabel!
    @IBOutlet weak var majorTickTransparancyReading: UILabel!
    @IBOutlet weak var minorTickTransparancyReading: UILabel!
    @IBOutlet weak var firstSection: UIView!
    @IBOutlet weak var secondSection: UIView!
    @IBOutlet weak var thirdSection: UIView!
    
    @IBOutlet weak var majorTickColor: UIColorWell!
    @IBOutlet weak var majorTickColorDark: UIColorWell!
    @IBOutlet weak var minorTickColor: UIColorWell!
    @IBOutlet weak var minorTickColorDark: UIColorWell!
    @IBOutlet weak var oddSolarTermColor: UIColorWell!
    @IBOutlet weak var oddSolarTermColorDark: UIColorWell!
    @IBOutlet weak var evenSolarTermColor: UIColorWell!
    @IBOutlet weak var evenSolarTermColorDark: UIColorWell!
    @IBOutlet weak var textColor: UIColorWell!
    @IBOutlet weak var textColorDark: UIColorWell!
    @IBOutlet weak var coreColor: UIColorWell!
    @IBOutlet weak var coreColorDark: UIColorWell!
    
    func fillData() {
        guard let layout = WatchFaceView.currentInstance?.watchLayout else { return }
        yearColor.gradient = layout.firstRing
        yearColorLoop.isOn = layout.firstRing.isLoop
        monthColor.gradient = layout.secondRing
        monthColorLoop.isOn = layout.secondRing.isLoop
        dayColor.gradient = layout.thirdRing
        dayColorLoop.isOn = layout.thirdRing.isLoop
        centerTextColor.gradient = layout.centerFontColor
        
        circleTransparancy.value = Float(layout.shadeAlpha)
        circleTransparancyReading.text = String(format: "%.2f", layout.shadeAlpha)
        backgroundTransparancy.value = Float(layout.backAlpha)
        backgroundTransparancyReading.text = String(format: "%.2f", layout.backAlpha)
        majorTickTransparancy.value = Float(layout.majorTickAlpha)
        majorTickTransparancyReading.text = String(format: "%.2f", layout.majorTickAlpha)
        minorTickTransparancy.value = Float(layout.minorTickAlpha)
        minorTickTransparancyReading.text = String(format: "%.2f", layout.minorTickAlpha)
        
        majorTickColor.selectedColor = UIColor(cgColor: layout.majorTickColor)
        majorTickColorDark.selectedColor = UIColor(cgColor: layout.majorTickColorDark)
        minorTickColor.selectedColor = UIColor(cgColor: layout.minorTickColor)
        minorTickColorDark.selectedColor = UIColor(cgColor: layout.minorTickColorDark)
        oddSolarTermColor.selectedColor = UIColor(cgColor: layout.oddSolarTermTickColor)
        oddSolarTermColorDark.selectedColor = UIColor(cgColor: layout.oddSolarTermTickColorDark)
        evenSolarTermColor.selectedColor = UIColor(cgColor: layout.evenSolarTermTickColor)
        evenSolarTermColorDark.selectedColor = UIColor(cgColor: layout.evenSolarTermTickColorDark)
        textColor.selectedColor = UIColor(cgColor: layout.fontColor)
        textColorDark.selectedColor = UIColor(cgColor: layout.fontColorDark)
        coreColor.selectedColor = UIColor(cgColor: layout.innerColor)
        coreColorDark.selectedColor = UIColor(cgColor: layout.innerColorDark)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        title = "圈色"
        navigationItem.largeTitleDisplayMode = .never
        firstSection.layer.cornerRadius = 10
        secondSection.layer.cornerRadius = 10
        thirdSection.layer.cornerRadius = 10
        fillData()
    }
    
    @IBAction func loopToggled(_ sender: UISwitch) {
        if sender === yearColorLoop {
            print(sender.isOn)
            yearColor.isLoop = sender.isOn
            yearColor.updateGradient()
        } else if sender === monthColorLoop {
            monthColor.isLoop = sender.isOn
            monthColor.updateGradient()
        } else if sender === dayColorLoop {
            dayColor.isLoop = sender.isOn
            dayColor.updateGradient()
        }
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        if sender === circleTransparancy {
            circleTransparancyReading.text = String(format: "%.2f", sender.value)
        } else if sender === backgroundTransparancy {
            backgroundTransparancyReading.text = String(format: "%.2f", sender.value)
        } else if sender === majorTickTransparancy {
           majorTickTransparancyReading.text = String(format: "%.2f", sender.value)
       } else if sender === minorTickTransparancy {
           minorTickTransparancyReading.text = String(format: "%.2f", sender.value)
       }
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
    
}

class MarkColorView: UIViewController {
    @IBOutlet weak var firstSection: UIView!
    @IBOutlet weak var secondSection: UIView!
    @IBOutlet weak var thirdSection: UIView!
    @IBOutlet weak var fourthSection: UIView!
    
    @IBOutlet weak var mercuryColor: UIColorWell!
    @IBOutlet weak var venusColor: UIColorWell!
    @IBOutlet weak var marsColor: UIColorWell!
    @IBOutlet weak var jupiterColor: UIColorWell!
    @IBOutlet weak var saturnColor: UIColorWell!
    @IBOutlet weak var moonColor: UIColorWell!
    
    @IBOutlet weak var newmoonMarkColor: UIColorWell!
    @IBOutlet weak var fullmoonMarkColor: UIColorWell!
    @IBOutlet weak var oddSolarTermMarkColor: UIColorWell!
    @IBOutlet weak var evenSolarTermMarkColor: UIColorWell!
    
    @IBOutlet weak var sunriseMarkColor: UIColorWell!
    @IBOutlet weak var sunsetMarkColor: UIColorWell!
    @IBOutlet weak var noonMarkColor: UIColorWell!
    @IBOutlet weak var midnightMarkColor: UIColorWell!
    
    @IBOutlet weak var moonriseMarkColor: UIColorWell!
    @IBOutlet weak var moonsetMarkColor: UIColorWell!
    @IBOutlet weak var moonnoonMarkColor: UIColorWell!
    
    func fillData() {
        guard let layout = WatchFaceView.currentInstance?.watchLayout else { return }
        mercuryColor.selectedColor = UIColor(cgColor: layout.planetIndicator[0])
        venusColor.selectedColor = UIColor(cgColor: layout.planetIndicator[1])
        marsColor.selectedColor = UIColor(cgColor: layout.planetIndicator[2])
        jupiterColor.selectedColor = UIColor(cgColor: layout.planetIndicator[3])
        saturnColor.selectedColor = UIColor(cgColor: layout.planetIndicator[4])
        moonColor.selectedColor = UIColor(cgColor: layout.planetIndicator[5])
        
        newmoonMarkColor.selectedColor = UIColor(cgColor: layout.eclipseIndicator)
        fullmoonMarkColor.selectedColor = UIColor(cgColor: layout.fullmoonIndicator)
        oddSolarTermMarkColor.selectedColor = UIColor(cgColor: layout.oddStermIndicator)
        evenSolarTermMarkColor.selectedColor = UIColor(cgColor: layout.evenStermIndicator)
        
        sunriseMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[0])
        sunsetMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[1])
        noonMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[2])
        midnightMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[3])
        
        moonriseMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[0])
        moonsetMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[1])
        moonnoonMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[2])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        title = "塊標色"
        navigationItem.largeTitleDisplayMode = .never
        firstSection.layer.cornerRadius = 10
        secondSection.layer.cornerRadius = 10
        thirdSection.layer.cornerRadius = 10
        fourthSection.layer.cornerRadius = 10
        fillData()
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
}

class LayoutsView: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var widthField: UITextField!
    @IBOutlet weak var heightField: UITextField!
    @IBOutlet weak var roundedCornerField: UITextField!
    @IBOutlet weak var largeTextShiftField: UITextField!
    @IBOutlet weak var textVerticalShiftField: UITextField!
    @IBOutlet weak var textHorizontalShiftField: UITextField!
    
    func fillData() {
        guard let layout = WatchFaceView.currentInstance?.watchLayout else { return }
        widthField.text = String(format: "%.0f", layout.watchSize.width)
        heightField.text = String(format: "%.0f", layout.watchSize.height)
        roundedCornerField.text = String(format: "%.2f", layout.cornerRadiusRatio)
        largeTextShiftField.text = String(format: "%.2f", layout.centerTextOffset)
        textVerticalShiftField.text = String(format: "%.2f", layout.verticalTextOffset)
        textHorizontalShiftField.text = String(format: "%.2f", layout.horizontalTextOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: "畢", style: .done, target: self, action: #selector(closeSetting(_:))), animated: false)
        title = "佈局"
        navigationItem.largeTitleDisplayMode = .never
        contentView.layer.cornerRadius = 10
        fillData()
    }
    
    @objc func closeSetting(_ sender: UIView) {
        navigationController?.dismiss(animated: true)
    }
}
