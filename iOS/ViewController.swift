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

extension UINavigationController {
    @objc func closeSetting(_ sender: UIView) {
        self.dismiss(animated: true)
    }
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
    
    func resize() {
        let screen = UIScreen.main.bounds
        let newSize = newSize(frame: screen.size, idealSize: watchFace!.watchLayout.watchSize)
        watchFace!.updateSize(with: CGRect(x: (screen.width - newSize.width) / 2.0, y: (screen.height - newSize.height) / 2.0,
                                           width: newSize.width, height: newSize.height))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        resize()
        watchFace.setAutoRefresh()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        watchFace!.addGestureRecognizer(longPressGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let launchedBefore = UserDefaults.standard.bool(forKey: "ChineseTimeLaunchedBefore")
        if !launchedBefore {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let welcome = storyBoard.instantiateViewController(withIdentifier: "WelcomeView") as! WelcomeViewController
            self.present(welcome, animated: true)
        }
        _ = WatchConnectivityManager.shared
    }
    
    @objc func longPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        case .ended:
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "Settings") as! UINavigationController
            self.present(settingsViewController, animated:true, completion:nil)
        default:
            break
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resize()
    }
}

class WelcomeViewController: UIViewController {
    @IBOutlet weak var appName: UILabel!
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var watchFaceTop: NSLayoutConstraint!
    @IBOutlet weak var contentTop: NSLayoutConstraint!
    @IBOutlet weak var text1: UITextView!
    @IBOutlet weak var text2: UITextView!
    @IBOutlet var button: UIButton!
    
    @IBAction func close(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: "ChineseTimeLaunchedBefore")
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize, weight: .black)
        button.configuration?.cornerStyle = .large
        contentTop.constant = max(0.25 * self.view.bounds.height - 100, 20)
        watchFaceTop.constant = max(0.12 * self.view.bounds.height - 40, 10)
        height.constant = 510.0 + contentTop.constant + watchFaceTop.constant - 60
        text1.text = NSLocalizedString("輪試設計介紹", comment: "Details about Ring Design")
        text2.text = NSLocalizedString("設置介紹", comment: "Details about Settings")
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
        
        let labelSize: CGSize
        if desp1 == nil && desp2 == nil && segment == nil {
            labelSize = CGSize(width: 200, height: 21)
        } else {
            labelSize = CGSize(width: 110, height: 21)
        }

        let label = UILabel()
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
                label1.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: bounds.height / 2 - labelSize.height - 1, width: CGRectGetMinX(arrow.frame) - CGRectGetMaxX(label.frame) - 30, height: labelSize.height)
                elements.addSubview(label1)
                let label2 = UILabel()
                label2.text = desp2
                label2.textColor = .secondaryLabel
                label2.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: bounds.height / 2 + 1, width: CGRectGetMinX(arrow.frame) - CGRectGetMaxX(label.frame) - 30, height: labelSize.height)
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
        elements.removeFromSuperview()
        segment?.removeFromSuperview()
        elements = UIView()
        title = nil
        pushView = nil
        desp1 = nil
        desp2 = nil
        segment = nil
    }
}

class SettingsViewController: UITableViewController {
    struct ButtonOption {
        let title: String
        let color: UIColor
        let action: (() -> Void)
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
    
    var models = [Section]()
    
    func createNextView(name: String) -> (() -> Void) {
        func openView() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nextView = storyboard.instantiateViewController(withIdentifier: name)
            navigationController?.pushViewController(nextView, animated: true)
        }
        return openView
    }
    
    func reload() {
        fillData()
        tableView.reloadData()
    }
    
    func fillData() {
        let time = WatchFaceView.currentInstance?.displayTime ?? Date()
        let timezone = WatchFaceView.currentInstance?.timezone ?? Calendar.current.timeZone
        let locationString = WatchFaceView.currentInstance?.location.map { coordinateDesp(coordinate: $0) }
        
        let globalMonthSegment = UISegmentedControl(items: [NSLocalizedString("精確至時刻", comment: "Leap month setting: precise"), NSLocalizedString("精確至日", comment: "Leap month setting: daily precision")])
        globalMonthSegment.selectedSegmentIndex = ChineseCalendar.globalMonth ? 0 : 1
        globalMonthSegment.addTarget(self, action: #selector(globalMonthToggled(segment:)), for: .allEvents)
        
        let apparentTimeSegment = UISegmentedControl(items: [NSLocalizedString("真太陽時", comment: "Time setting: apparent solar time"), NSLocalizedString("標準時", comment: "Time setting: mean solar time")])
        apparentTimeSegment.isEnabled = WatchFaceView.currentInstance?.location != nil
        apparentTimeSegment.selectedSegmentIndex = WatchFaceView.currentInstance?.location == nil ? 1 : (ChineseCalendar.apparentTime ? 0 : 1)
        apparentTimeSegment.addTarget(self, action: #selector(apparentTimeToggled(segment:)), for: .allEvents)

        models = [
            Section(title: NSLocalizedString("數據", comment: "Data Source"), options: [
                .dual(model: DuelOption(title: NSLocalizedString("置閏法", comment: "Leap month setting"), segment: globalMonthSegment)),
                .dual(model: DuelOption(title: NSLocalizedString("時間", comment: "Time setting"), segment: apparentTimeSegment)),
                .detail(model: DetailOption(title: NSLocalizedString("顯示時間", comment: "Display time"), action: createNextView(name: "DateTime"),
                                                                       desp1: time.formatted(date: .numeric, time: .shortened), desp2: timezone.localizedName(for: .generic, locale: Locale.current))),
                .detail(model: DetailOption(title: NSLocalizedString("經緯度", comment: "Location"), action: createNextView(name: "Location"), desp1: locationString?.0, desp2: locationString?.1))
            ]),
            Section(title: NSLocalizedString("樣式", comment: "Styles"), options: [
                .detail(model: DetailOption(title: NSLocalizedString("圈色", comment: "Circle colors"), action: createNextView(name: "CircleColors"), desp1: nil, desp2: nil)),
                .detail(model: DetailOption(title: NSLocalizedString("塊標色", comment: "Mark colors"), action: createNextView(name: "MarkColors"), desp1: nil, desp2: nil)),
                .detail(model: DetailOption(title: NSLocalizedString("佈局", comment: "Layout parameters"), action: createNextView(name: "Layouts"), desp1: nil, desp2: nil))
            ]),
            Section(title: NSLocalizedString("其它", comment: "Action"), options: [
                .detail(model: DetailOption(title: NSLocalizedString("主題庫", comment: "manage saved layouts"), action: createNextView(name: "ThemeList"), desp1: nil, desp2: nil)),
                .detail(model: DetailOption(title: NSLocalizedString("注釋", comment: "Help Doc"), action: createNextView(name: "HelpView"), desp1: nil, desp2: nil))
            ])
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("設置", comment: "Settings View")
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.register(TableCell.self, forCellReuseIdentifier: TableCell.identifier)
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
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let data = models[indexPath.section].options[indexPath.row]
        switch data {
        case .detail(model: let model):
            if model.desp1 != nil && model.desp2 != nil {
                return 60
            } else {
                return 44
            }
        default:
            return 44
        }
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
        case .dual(model: let model):
            cell.title = model.title
            cell.segment = model.segment
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = (tableView.cellForRow(at: indexPath) as! TableCell)
        if let action = cell.pushView {
            action()
        }
    }
    
    @objc func globalMonthToggled(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            ChineseCalendar.globalMonth = true
        } else if segment.selectedSegmentIndex == 1 {
            ChineseCalendar.globalMonth = false
        }
        UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
    }
    @objc func apparentTimeToggled(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            ChineseCalendar.apparentTime = true
            if WatchFaceView.currentInstance?.location == nil {
                segment.selectedSegmentIndex = 1
            }
        } else if segment.selectedSegmentIndex == 1 {
            ChineseCalendar.apparentTime = false
        }
        UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
    }
}

class LocationView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    static var currentInstance: LocationView?
    
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var longitudePicker: UIPickerView!
    @IBOutlet weak var latitudePicker: UIPickerView!
    @IBOutlet weak var display: UITextField!
    @IBOutlet weak var toggleView: UIView!
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var pickerView: UIView!
    @IBOutlet weak var locationOptions: UISegmentedControl!
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet weak var currentLocationSwitch: UISwitch!
    
    var longitude: [Int] = [0, 0, 0, 0]
    var latitude: [Int] = [0, 0, 0, 0]
    
    func makeSelection(value: Double, picker: UIPickerView) {
        var values = [0, 0, 0, 0]
        values[3] = value >= 0 ? 0 : 1
        picker.selectRow(values[3], inComponent: 3, animated: true)
        let tempValue = Int(round(abs(value) * 3600))
        values[0] = tempValue / 3600
        if picker === longitudePicker {
            picker.selectRow(values[0] + 180*10, inComponent: 0, animated: true)
        } else if picker == latitudePicker {
            picker.selectRow(values[0] + 90*10, inComponent: 0, animated: true)
        }
        values[1] = (tempValue % 3600) / 60
        picker.selectRow(values[1] + 60*10, inComponent: 1, animated: true)
        values[2] = tempValue % 60
        picker.selectRow(values[2] + 60*10, inComponent: 2, animated: true)
        if picker === longitudePicker {
            longitude = values
        } else if picker === latitudePicker {
            latitude = values
        }
    }
    
    func chooseLocationOption(of choice: Int) { // Will not trigger requestLocation
        if choice == 0 {
            LocationManager.shared.enabled = false
            locationOptions.selectedSegmentIndex = 0
            pickerView.isHidden = false
            displayView.isHidden = true
            viewHeight.constant = CGRectGetMaxY(pickerView.frame) + 20
            if let location = WatchLayout.shared.location ?? LocationManager.shared.location {
                makeSelection(value: location.y, picker: longitudePicker)
                makeSelection(value: location.x, picker: latitudePicker)
            } else {
                makeSelection(value: 0, picker: longitudePicker)
                makeSelection(value: 0, picker: latitudePicker)
            }
        } else if choice == 1 {
            LocationManager.shared.enabled = true
            locationOptions.selectedSegmentIndex = 1
            pickerView.isHidden = true
            displayView.isHidden = false
            viewHeight.constant = CGRectGetMaxY(displayView.frame) + 20
            if let location = LocationManager.shared.location {
                let locationString = coordinateDesp(coordinate: location)
                self.display.text = "\(locationString.0), \(locationString.1)"
            } else {
                display.text = NSLocalizedString("虚無", comment: "Location fails to load")
            }
        }
    }

    func fillData() {
        if WatchFaceView.currentInstance?.location != nil {
            currentLocationSwitch.isOn = true
            locationTitle.isHidden = false
            locationOptions.isEnabled = true
            if LocationManager.shared.enabled {
                chooseLocationOption(of: 1)
                LocationManager.shared.requestLocation() { location in
                    if location != nil {
                        self.chooseLocationOption(of: 1)
                    } else {
                        self.chooseLocationOption(of: 0)
                    }
                }
            } else {
                chooseLocationOption(of: 0)
            }
        } else {
            currentLocationSwitch.isOn = false
            locationTitle.isHidden = true
            pickerView.isHidden = true
            displayView.isHidden = true
            locationOptions.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("經緯度", comment: "Location View")
        navigationItem.largeTitleDisplayMode = .never
        pickerView.layer.cornerRadius = 10
        displayView.layer.cornerRadius = 10
        toggleView.layer.cornerRadius = 10
        longitudePicker.delegate = self
        longitudePicker.dataSource = self
        latitudePicker.delegate = self
        latitudePicker.dataSource = self
        Self.currentInstance = self
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        fillData()
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
            let numbers = [0: 180 * 20, 1: 60 * 20, 2: 60 * 20, 3: 2]
            return numbers[component]!
        } else if pickerView === latitudePicker {
            let numbers = [0: 90 * 20, 1: 60 * 20, 2: 60 * 20, 3: 2]
            return numbers[component]!
        } else {
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0, 1, 2:
            if pickerView === longitudePicker {
                if component == 0 {
                    return "\(row % 180)"
                } else {
                    return "\(row % 60)"
                }
            } else if pickerView === latitudePicker {
                if component == 0 {
                    return "\(row % 90)"
                } else {
                    return "\(row % 60)"
                }
            } else {
                return nil
            }
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
        LocationManager.shared.location = nil
        if pickerView === longitudePicker {
            switch component {
            case 0:
                longitude[component] = row % 180
            case 1, 2:
                longitude[component] = row % 60
            case 3:
                longitude[component] = row
            default:
                break
            }
        } else if pickerView === latitudePicker {
            switch component {
            case 0:
                latitude[component] = row % 90
            case 1, 2:
                latitude[component] = row % 60
            case 3:
                latitude[component] = row
            default:
                break
            }
        }
        let coordinate = readCoordinate()
        WatchLayout.shared.location = coordinate
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
    }
    
    @IBAction func currentLocationToggled(_ sender: UISwitch) {
        if currentLocationSwitch.isOn {
            locationOptions.isEnabled = true
            locationTitle.isHidden = false
            if LocationManager.shared.enabled {
                LocationManager.shared.requestLocation() { location in
                    if location != nil {
                        self.chooseLocationOption(of: 1)
                        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
                        (self.navigationController?.viewControllers.first as? SettingsViewController)?.reload()
                    } else {
                        self.chooseLocationOption(of: 0)
                    }
                }
            } else {
                chooseLocationOption(of: 0)
            }
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
            (self.navigationController?.viewControllers.first as? SettingsViewController)?.reload()
        } else {
            locationTitle.isHidden = true
            pickerView.isHidden = true
            displayView.isHidden = true
            locationOptions.isEnabled = false
            viewHeight.constant = CGRectGetMaxY(toggleView.frame) + 20
            LocationManager.shared.location = nil
            WatchLayout.shared.location = nil
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
            (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
        }
    }
    
    func presentLocationUnavailable() {
        let alertController = UIAlertController(title: NSLocalizedString("怪哉", comment: "Location not enabled but tried to locate title"), message: NSLocalizedString("蓋因定位未開啓", comment: "Location not enabled but tried to locate message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("作罷", comment: "Ok"), style: .default)

        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func locationOptionToggled(_ sender: UISegmentedControl) {
        chooseLocationOption(of: sender.selectedSegmentIndex)
        UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
        if sender.selectedSegmentIndex == 1 {
            LocationManager.shared.enabled = true
            LocationManager.shared.requestLocation() { location in
                if location != nil {
                    self.chooseLocationOption(of: 1)
                    WatchFaceView.currentInstance?.drawView(forceRefresh: true)
                    (self.navigationController?.viewControllers.first as? SettingsViewController)?.reload()
                } else {
                    self.chooseLocationOption(of: 0)
                    self.presentLocationUnavailable()
                }
            }
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
            (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
        } else if sender.selectedSegmentIndex == 0 {
            LocationManager.shared.enabled = false
            LocationManager.shared.location = nil
            let coordinate = readCoordinate()
            WatchLayout.shared.location = coordinate
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
            (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
        }
    }
}

class DateTimeView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var datetimePicker: UIDatePicker!
    @IBOutlet weak var timezonePicker: UIPickerView!
    @IBOutlet weak var currentTime: UISwitch!
    @IBOutlet weak var contentView: UIView!
    
    var panelTimezone = Calendar.current.timeZone
    var timeZones = DataTree(name: "Root")
    var timer: Timer?
    
    func populateTimezones() {
        let allTimezones = TimeZone.knownTimeZoneIdentifiers
        for timezone in allTimezones {
            let components = timezone.split(separator: "/")
        var currentNode: DataTree? = timeZones
            for component in components {
                currentNode = currentNode?.add(element: String(component))
            }
        }
    }
    
    func selectTimezone(timezone: TimeZone) {
        let components = timezone.identifier.split(separator: "/")
        var currentNode: DataTree? = timeZones
        for i in 0..<components.count {
            if let index = currentNode?.index(of: String(components[i])) {
                timezonePicker.reloadComponent(i)
                timezonePicker.selectRow(index, inComponent: i, animated: true)
                currentNode = currentNode?[index]
            }
        }
        for i in components.count..<self.numberOfComponents(in: timezonePicker) {
            timezonePicker.reloadComponent(i)
        }
    }
    
    func fillData() {
        if let date = WatchFaceView.currentInstance?.displayTime {
            datetimePicker.date = date
            currentTime.isOn = false
        } else {
            currentTime.isOn = true
        }
        let timezone: TimeZone? = WatchFaceView.currentInstance?.timezone
        if let timezone = timezone {
            panelTimezone = timezone
        }
        selectTimezone(timezone: panelTimezone)
    }
    
    override func viewDidLoad() {
        populateTimezones()
        timezonePicker.delegate = self
        timezonePicker.dataSource = self
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        super.viewDidLoad()
        title = NSLocalizedString("顯示時間", comment: "Display Time View")
        navigationItem.largeTitleDisplayMode = .never
        contentView.layer.cornerRadius = 10
        datetimePicker.contentHorizontalAlignment = .center
        fillData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        selectTimezone(timezone: panelTimezone)

    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return timeZones.maxLevel
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var currentNode: DataTree? = timeZones
        for i in 0..<component {
            let row = pickerView.selectedRow(inComponent: i)
            currentNode = currentNode?[row]
        }
        return currentNode?.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var currentNode: DataTree? = timeZones
        for i in 0..<component {
            let previousRow = pickerView.selectedRow(inComponent: i)
            currentNode = currentNode?[previousRow]
        }
        let title = currentNode?[row]?.nodeName
        return title.map { String($0.replacingOccurrences(of: "_", with: " ")) }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var currentNode: DataTree? = timeZones
        var timezoneId = [String]()
        for i in 0...component {
            let previousRow = pickerView.selectedRow(inComponent: i)
            currentNode = currentNode?[previousRow]
            if let node = currentNode {
                timezoneId.append(node.nodeName)
            }
        }
        let identifier = String(timezoneId.joined(separator: "/"))
        if let timezone = TimeZone(identifier: identifier) {
            WatchFaceView.currentInstance?.timezone = timezone
            datetimePicker.date = datetimePicker.date.convertToTimeZone(initTimeZone: panelTimezone, timeZone: timezone)
            panelTimezone = timezone
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
            (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
        }
        for i in (component+1)..<pickerView.numberOfComponents {
            pickerView.reloadComponent(i)
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel

        if let view = view {
            label = view as! UILabel
        } else {
            label = UILabel()
            label.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
            label.lineBreakMode = .byTruncatingTail
            label.numberOfLines = 1
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
        }

        label.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        return label
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        currentTime.isOn = false
        let selectedDate = datetimePicker.date.convertToTimeZone(initTimeZone: panelTimezone, timeZone: Calendar.current.timeZone)
        let secondDiff = Calendar.current.component(.second, from: selectedDate)
        WatchFaceView.currentInstance?.displayTime = selectedDate.advanced(by: -Double(secondDiff))
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
    }
    @IBAction func currentDateToggled(_ sender: UISwitch) {
        if currentTime.isOn {
            WatchFaceView.currentInstance?.displayTime = nil
            WatchFaceView.currentInstance?.timezone = Calendar.current.timeZone
            datetimePicker.date = Date()
            selectTimezone(timezone: Calendar.current.timeZone)
        } else {
            WatchFaceView.currentInstance?.displayTime = datetimePicker.date
        }
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
    }
}

class ColorWell: UIColorWell {
    var index: Int!
    
    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        guard let slider = self.superview as? GradientSlider else { return }
        let translation = sender.translation(in: slider)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: slider)
        if sender.state == .ended {
            if slider.bounds.contains(self.center) || slider.controls.count <= 2 {
                self.frame = CGRect(x: frame.origin.x, y: (slider.bounds.height - frame.height) / 2, width: frame.width, height: frame.height)
                slider.values[index] = (center.x - slider.bounds.origin.x) / (slider.bounds.width - slider.controlRadius * 2)
            } else {
                self.removeFromSuperview()
                slider.removeControl(at: index)
                UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
            }
            slider.updateGradient()
            if let action = slider.action {
                action()
            }
        }
    }
    
    @objc func colorWellChanged(_ sender: Any) {
        guard let slider = self.superview as? GradientSlider else { return }
        if let color = self.selectedColor {
            slider.colors[index] = color
            slider.updateGradient()
            if let action = slider.action {
                action()
            }
        }
    }
}

class GradientSlider: UIControl, UIGestureRecognizerDelegate {
    let minimumValue: CGFloat = 0
    let maximumValue: CGFloat = 1
    var values: [CGFloat] = [0, 1]
    var colors: [UIColor] = [.black, .white]
    internal var controls = [ColorWell]()
    var action: (() -> Void)?
    
    var isLoop = false
    private let trackLayer = CAGradientLayer()
    internal var controlRadius: CGFloat = 0
    
    var gradient: WatchLayout.Gradient {
        get {
            return WatchLayout.Gradient(locations: values, colors: colors.map{$0.cgColor}, loop: isLoop)
        } set {
            if newValue.isLoop {
                values = newValue.locations.dropLast()
                colors = newValue.colors.dropLast().map { UIColor(cgColor: $0) }
            } else {
                values = newValue.locations
                colors = newValue.colors.map { UIColor(cgColor: $0) }
            }
            isLoop = newValue.isLoop
            updateLayerFrames()
            initializeControls()
            updateGradient()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        layer.addSublayer(trackLayer)
        updateLayerFrames()
        initializeControls()
        updateGradient()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self) {
            let ratio = (location.x - bounds.origin.x - controlRadius) / (bounds.width - controlRadius * 2)
            let color = UIColor(cgColor: self.gradient.interpolate(at: ratio))
            addControl(at: ratio, color: color)
            values.append(ratio)
            colors.append(color)
            UIImpactFeedbackGenerator.init(style: .rigid).impactOccurred()
            updateGradient()
            if let action = action {
                action()
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
            changeChontrols()
        }
    }

    private func addControl(at value: CGFloat, color: UIColor) {
        let control = ColorWell()
        control.frame = CGRect(origin: thumbOriginForValue(value), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        control.selectedColor = color
        let panGesture = UIPanGestureRecognizer(target: control, action: #selector(ColorWell.dragged(_:)))
        control.isUserInteractionEnabled = true
        control.addGestureRecognizer(panGesture)
        control.addTarget(control, action: #selector(ColorWell.colorWellChanged(_:)), for: .allEvents)
        controls.append(control)
        control.index = controls.count - 1
        self.addSubview(control)
    }
    
    private func initializeControls() {
        for control in controls.reversed() {
            control.removeFromSuperview()
        }
        controls = []
        for i in 0..<values.count {
            addControl(at: values[i], color: colors[i])
        }
    }
    
    func removeControl(at index: Int) {
        colors.remove(at: index)
        values.remove(at: index)
        controls.remove(at: index)
        for i in index..<controls.count {
            controls[i].index = i
        }
    }
    
    private func changeChontrols() {
        for i in 0..<controls.count {
            controls[i].frame = CGRect(origin: thumbOriginForValue(values[i]), size: CGSize(width: controlRadius * 2, height: controlRadius * 2))
        }
    }
    
    private func updateLayerFrames() {
        trackLayer.frame = bounds.insetBy(dx: bounds.height / 2, dy: bounds.height * 0.42)
        let mask = CAShapeLayer()
        let maskShape = RoundedRect(rect: trackLayer.bounds, nodePos: trackLayer.frame.height / 2, ankorPos: trackLayer.frame.height / 5).path
        mask.path = maskShape
        trackLayer.mask = mask
        controlRadius = bounds.height / 3
        trackLayer.startPoint = CGPoint(x: 0, y: 0)
        trackLayer.endPoint = CGPoint(x: 1, y: 0)
    }
    
    func updateGradient() {
        let gradient = self.gradient
        trackLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
        trackLayer.colors = gradient.colors
    }

    func positionForValue(_ value: CGFloat) -> CGFloat {
        return trackLayer.frame.width * value
    }

    private func thumbOriginForValue(_ value: CGFloat) -> CGPoint {
        let x = positionForValue(value) - controlRadius
        return CGPoint(x: trackLayer.frame.minX + x, y: bounds.height / 2 - controlRadius)
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
    @IBOutlet weak var majorTickTransparancy: UISlider!
    @IBOutlet weak var minorTickTransparancy: UISlider!
    @IBOutlet weak var circleTransparancyReading: UILabel!
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
        let layout = WatchLayout.shared
        yearColor.gradient = layout.firstRing
        yearColorLoop.isOn = layout.firstRing.isLoop
        monthColor.gradient = layout.secondRing
        monthColorLoop.isOn = layout.secondRing.isLoop
        dayColor.gradient = layout.thirdRing
        dayColorLoop.isOn = layout.thirdRing.isLoop
        centerTextColor.gradient = layout.centerFontColor
        
        circleTransparancy.value = Float(layout.shadeAlpha)
        circleTransparancyReading.text = String(format: "%.2f", layout.shadeAlpha)
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
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        title = NSLocalizedString("圈色", comment: "Circle Color View")
        navigationItem.largeTitleDisplayMode = .never
        firstSection.layer.cornerRadius = 10
        secondSection.layer.cornerRadius = 10
        thirdSection.layer.cornerRadius = 10
        yearColor.action = {
            WatchLayout.shared.firstRing = self.yearColor.gradient
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        }
        monthColor.action = {
            WatchLayout.shared.secondRing = self.monthColor.gradient
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        }
        dayColor.action = {
            WatchLayout.shared.thirdRing = self.dayColor.gradient
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        }
        centerTextColor.action = {
            WatchLayout.shared.centerFontColor = self.centerTextColor.gradient
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        }
        fillData()
        
        majorTickColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        majorTickColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        minorTickColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        minorTickColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        oddSolarTermColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        oddSolarTermColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        evenSolarTermColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        evenSolarTermColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        textColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        textColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        coreColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        coreColorDark.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
    }
    
    @IBAction func loopToggled(_ sender: UISwitch) {
        let watchLayout = WatchLayout.shared
        if sender === yearColorLoop {
            yearColor.isLoop = sender.isOn
            yearColor.updateGradient()
            watchLayout.firstRing = yearColor.gradient
        } else if sender === monthColorLoop {
            monthColor.isLoop = sender.isOn
            monthColor.updateGradient()
            watchLayout.secondRing = monthColor.gradient
        } else if sender === dayColorLoop {
            dayColor.isLoop = sender.isOn
            dayColor.updateGradient()
            watchLayout.thirdRing = dayColor.gradient
        }
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
    }
    
    @IBAction func transparencyChanged(_ sender: UISlider) {
        let watchLayout = WatchLayout.shared
        if sender === circleTransparancy {
            circleTransparancyReading.text = String(format: "%.2f", sender.value)
            watchLayout.shadeAlpha = CGFloat(circleTransparancy.value)
        } else if sender === majorTickTransparancy {
            majorTickTransparancyReading.text = String(format: "%.2f", sender.value)
            watchLayout.majorTickAlpha = CGFloat(majorTickTransparancy.value)
        } else if sender === minorTickTransparancy {
            minorTickTransparancyReading.text = String(format: "%.2f", sender.value)
            watchLayout.minorTickAlpha = CGFloat(minorTickTransparancy.value)
        }
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
    }
    
    @objc func colorChanged(_ sender: UIColorWell) {
        let watchLayout = WatchLayout.shared
        if sender === majorTickColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.majorTickColor = color
            }
        } else if sender === majorTickColorDark {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.majorTickColorDark = color
            }
        } else if sender === majorTickColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.majorTickColor = color
            }
        } else if sender === minorTickColorDark {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.minorTickColorDark = color
            }
        } else if sender === oddSolarTermColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.oddSolarTermTickColor = color
            }
        } else if sender === oddSolarTermColorDark {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.oddSolarTermTickColorDark = color
            }
        } else if sender === evenSolarTermColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.evenSolarTermTickColor = color
            }
        } else if sender === evenSolarTermColorDark {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.evenSolarTermTickColorDark = color
            }
        } else if sender === textColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.fontColor = color
            }
        } else if sender === textColorDark {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.fontColorDark = color
            }
        } else if sender === coreColor {
           if let color = sender.selectedColor?.cgColor {
               watchLayout.innerColor = color
           }
       } else if sender === coreColorDark {
           if let color = sender.selectedColor?.cgColor {
               watchLayout.innerColorDark = color
           }
       }
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
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
        let layout = WatchLayout.shared
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
        
        sunriseMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[1])
        sunsetMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[3])
        noonMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[2])
        midnightMarkColor.selectedColor = UIColor(cgColor: layout.sunPositionIndicator[0])
        
        moonriseMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[0])
        moonsetMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[2])
        moonnoonMarkColor.selectedColor = UIColor(cgColor: layout.moonPositionIndicator[1])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        title = NSLocalizedString("塊標色", comment: "Mark Color View")
        navigationItem.largeTitleDisplayMode = .never
        firstSection.layer.cornerRadius = 10
        secondSection.layer.cornerRadius = 10
        thirdSection.layer.cornerRadius = 10
        fourthSection.layer.cornerRadius = 10
        fillData()
        
        mercuryColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        venusColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        marsColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        jupiterColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        saturnColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        moonColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        newmoonMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        fullmoonMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        oddSolarTermMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        evenSolarTermMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        sunriseMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        sunsetMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        noonMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        midnightMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        moonriseMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        moonsetMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
        moonnoonMarkColor.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)
    }
    
    @objc func colorChanged(_ sender: UIColorWell) {
        let watchLayout = WatchLayout.shared
        if sender === mercuryColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[0] = color
            }
        } else if sender === venusColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[1] = color
            }
        } else if sender === marsColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[2] = color
            }
        } else if sender === jupiterColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[3] = color
            }
        } else if sender === saturnColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[4] = color
            }
        } else if sender === moonColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.planetIndicator[5] = color
            }
        } else if sender === newmoonMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.eclipseIndicator = color
            }
        } else if sender === fullmoonMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.fullmoonIndicator = color
            }
        } else if sender === oddSolarTermMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.oddStermIndicator = color
            }
        } else if sender === evenSolarTermMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.evenStermIndicator = color
            }
        } else if sender === sunriseMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.sunPositionIndicator[1] = color
            }
        } else if sender === sunsetMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.sunPositionIndicator[3] = color
            }
        } else if sender === noonMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.sunPositionIndicator[2] = color
            }
        } else if sender === midnightMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.sunPositionIndicator[0] = color
            }
        } else if sender === moonriseMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.moonPositionIndicator[0] = color
            }
        } else if sender === moonsetMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.moonPositionIndicator[2] = color
            }
        } else if sender === moonnoonMarkColor {
            if let color = sender.selectedColor?.cgColor {
                watchLayout.moonPositionIndicator[1] = color
            }
        }
        WatchFaceView.currentInstance?.drawView(forceRefresh: true)
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
        let layout = WatchLayout.shared
        widthField.text = String(format: "%.0f", layout.watchSize.width)
        heightField.text = String(format: "%.0f", layout.watchSize.height)
        roundedCornerField.text = String(format: "%.2f", layout.cornerRadiusRatio)
        largeTextShiftField.text = String(format: "%.2f", layout.centerTextOffset)
        textVerticalShiftField.text = String(format: "%.2f", layout.verticalTextOffset)
        textHorizontalShiftField.text = String(format: "%.2f", layout.horizontalTextOffset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        title = NSLocalizedString("佈局", comment: "Layout Parameter View")
        navigationItem.largeTitleDisplayMode = .never
        contentView.layer.cornerRadius = 10
        fillData()
    }
    
    @IBAction func widthChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.watchSize.width = value
            (WatchFaceView.currentInstance?.window?.rootViewController as? ViewController)?.resize()
        } else {
            sender.text = nil
        }
    }
    @IBAction func heightChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.watchSize.height = value
            (WatchFaceView.currentInstance?.window?.rootViewController as? ViewController)?.resize()
        } else {
            sender.text = nil
        }
    }
    @IBAction func radiusChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.cornerRadiusRatio = value
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        } else {
            sender.text = nil
        }
    }
    @IBAction func largeTextShiftChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.centerTextOffset = value
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        } else {
            sender.text = nil
        }
    }
    @IBAction func textVerticalShiftChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.verticalTextOffset = value
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        } else {
            sender.text = nil
        }
    }
    @IBAction func textHorizontalShiftChanged(_ sender: UITextField) {
        if let value = sender.text.flatMap({Double($0)}) {
            WatchLayout.shared.horizontalTextOffset = value
            WatchFaceView.currentInstance?.drawView(forceRefresh: true)
        } else {
            sender.text = nil
        }
    }
}

class HelpViewController: UIViewController {
    
    @IBOutlet var stackView: UIStackView!
    private let parser = MarkdownParser()
    
    func boldText(line: String, fontSize: CGFloat) -> NSAttributedString {
        let boldRanges = line.boldRanges
        let attrStr = NSMutableAttributedString()
        if !boldRanges.isEmpty {
            var boldRangesIndex = boldRanges.startIndex
            var startIndex = line.startIndex
            while boldRangesIndex < boldRanges.endIndex {
                let boldRange = boldRanges[boldRangesIndex]
                let plainText = line[startIndex..<line.index(boldRange.lowerBound, offsetBy: -2)]
                attrStr.append(NSAttributedString(string: String(plainText), attributes: [.font: UIFont.systemFont(ofSize: fontSize)]))
                startIndex = line.index(boldRange.upperBound, offsetBy: 2)
                let boldSubtext = line[boldRange]
                attrStr.append(NSAttributedString(string: String(boldSubtext), attributes: [.font: UIFont.boldSystemFont(ofSize: fontSize)]))
                boldRangesIndex = boldRanges.index(after: boldRangesIndex)
            }
            let remainingText = line[startIndex...]
            attrStr.append(NSAttributedString(string: String(remainingText), attributes: [.font: UIFont.systemFont(ofSize: fontSize)]))
        } else {
            let text = line.trimmingCharacters(in: .whitespaces)
            attrStr.append(NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize)]))
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
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        title = NSLocalizedString("注釋", comment: "Help Doc")
        navigationItem.largeTitleDisplayMode = .never
        stackView.spacing = 16
        view.backgroundColor = UIColor(named: "tableBack")

        let elements = parser.parse(helpString)

        for i in 0..<elements.count {
            let element = elements[i]
            
            switch element {
            case .heading(_, let text):
                let card: UIStackView = {
                    let stackView = UIStackView()
                    stackView.axis = .vertical
                    stackView.alignment = .fill
                    stackView.distribution = .fill
                    stackView.spacing = 15
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    stackView.layer.cornerRadius = 10
                    stackView.isLayoutMarginsRelativeArrangement = true
                    stackView.layoutMargins = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
                    stackView.backgroundColor = UIColor(named: "groupBack")
                    return stackView
                }()

                let row: UIStackView = {
                    let stackView = UIStackView()
                    stackView.axis = .horizontal
                    stackView.alignment = .fill
                    stackView.distribution = .equalCentering
                    stackView.spacing = 8
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapHeading(_:))))
                    return stackView
                }()
                
                let titleLabel = {
                    let label = UILabel()
                    label.attributedText = boldText(line: text, fontSize: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.isUserInteractionEnabled = true
                    return label
                }()
                
                let collapseIndicator = {
                    let arrow = UIImageView()
                    arrow.image = UIImage(systemName: "chevron.down")
                    arrow.contentMode = .scaleAspectFit
                    arrow.tintColor = UIColor.secondaryLabel
                    NSLayoutConstraint.activate([arrow.widthAnchor.constraint(equalToConstant: UIFont.labelFontSize)])
                    return arrow
                }()
                
                row.addArrangedSubview(titleLabel)
                row.addArrangedSubview(collapseIndicator)
                card.addArrangedSubview(row)
                stackView.addArrangedSubview(card)
                
            case .paragraph(text: let text):
                let label = UILabel()
                label.attributedText = boldText(line: text, fontSize: UIFont.systemFontSize)
                label.numberOfLines = 0
                label.isHidden = true
                if let card = stackView.arrangedSubviews.last as? UIStackView {
                    card.addArrangedSubview(label)
                }
            }
        }
    }

    @objc func didTapHeading(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25) {
            guard let card = sender.view?.superview as? UIStackView else { return }
            var showOrHide = false
            for view in card.arrangedSubviews {
                if !(view === sender.view) {
                    view.isHidden.toggle()
                    showOrHide = view.isHidden
                }
            }
            guard let stackView = sender.view as? UIStackView, let arrow = stackView.arrangedSubviews.last as? UIImageView else { return }
            if showOrHide {
                arrow.image = UIImage(systemName: "chevron.down")
            } else {
                arrow.image = UIImage(systemName: "chevron.up")
            }
            card.layoutIfNeeded()
        }
    }
}

class ThemeCell: UITableViewCell {
    static let identifier = "ThemeCell"
    var title: String?
    var deviceName: String?
    var date: Date?
    var elements = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let title = title else { return }
        elements.removeFromSuperview()
        elements = UIView()
        
        let labelSize = CGSize(width: bounds.width / 2 - 25, height: 21)
        let label = UILabel()
        label.frame = CGRect(x: 15, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
        label.text = title
        label.textColor = UIColor.label
        label.textAlignment = .left
        
        let dateLabel = UILabel()
        if let date = date {
            dateLabel.frame = CGRect(x: bounds.width - labelSize.width - 15, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
            if date.formatted(date: .numeric, time: .omitted) == Date().formatted(date: .numeric, time: .omitted) {
                dateLabel.text = date.formatted(date: .omitted, time: .shortened)
            } else {
                dateLabel.text = date.formatted(date: .abbreviated, time: .omitted)
            }
            dateLabel.textColor = UIColor.secondaryLabel
            dateLabel.textAlignment = .right
            
            elements.addSubview(dateLabel)
        } else {
            label.frame = CGRect(x: (bounds.width - labelSize.width) / 2, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
            label.textAlignment = .center
            label.textColor = .systemGreen
        }
        elements.addSubview(label)
        self.addSubview(elements)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
        deviceName = nil
        date = nil
    }
    
}

class ThemeListViewController: UITableViewController {
    var themes: [String: [DataContainer.SavedTheme]] = [:]
    let currentDeviceName = DataContainer.shared.deviceName
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        title = NSLocalizedString("主題庫", comment: "manage saved themes")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.setRightBarButton(UIBarButtonItem(title: NSLocalizedString("畢", comment: "Close settings panel"), style: .done, target: navigationController, action: #selector(UINavigationController.closeSetting(_:))), animated: false)
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.register(ThemeCell.self, forCellReuseIdentifier: ThemeCell.identifier)
        
        refreshControl = UIRefreshControl()
        refreshControl!.largeContentTitle = NSLocalizedString("刷新", comment: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressRecognizer.minimumPressDuration = 0.5
        self.tableView.addGestureRecognizer(longPressRecognizer)
        
        tableView.tableFooterView = {() -> UIView in
            let footnote = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 21))
            footnote.text = NSLocalizedString("短按換主題，長按易名", comment: "Comment: tap to change theme, long press to rename")
            footnote.textAlignment = .center
            footnote.textColor = .secondaryLabel
            footnote.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
            return footnote
        }()
        
        loadThemes()
    }
    
    @objc func refresh() {
        loadThemes()
        tableView.reloadData()
        self.refreshControl!.endRefreshing()
    }
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                if indexPath.section > 0 {
                    let cell = (tableView.cellForRow(at: indexPath) as! ThemeCell)
                    let alertController = UIAlertController(title: NSLocalizedString("易名", comment: "rename"), message: NSLocalizedString("不得爲空，不得重名", comment: "no blank, no duplicate name"), preferredStyle: .alert)
                    let renameAction = UIAlertAction(title: NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), style: .default) { _ in
                        DataContainer.shared.renameSave(name: cell.title!, deviceName: cell.deviceName!, newName: alertController.textFields![0].text!)
                        self.refresh()
                    }
                    let cancelAction = UIAlertAction(title: NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), style: .default)
                    alertController.addTextField { textField in
                        textField.text = cell.title
                        textField.addTarget(self, action: #selector(self.validateName(_:)), for: .editingChanged)
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(renameAction)
                    alertController.actions[1].isEnabled = false
                    present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func loadThemes() {
        themes = [:]
        let loadedThemes = DataContainer.shared.listAll()
        for theme in loadedThemes {
            if themes[theme.deviceName] == nil {
                themes[theme.deviceName] = [theme]
            } else {
                themes[theme.deviceName]!.append(theme)
            }
        }
        for deviceName in themes.keys {
            themes[deviceName]!.sort { $0.modifiedDate > $1.modifiedDate }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return themes.count + 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let keys = themes.keys.sorted { $0 == currentDeviceName || $0 > $1 }
            let key = keys[keys.index(keys.startIndex, offsetBy: section - 1)]
            return themes[key]?.count ?? 0
        }
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else {
            let keys = themes.keys.sorted { $0 == currentDeviceName || $0 > $1 }
            return keys[keys.index(keys.startIndex, offsetBy: section - 1)]
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = ThemeCell()
            cell.title = NSLocalizedString("謄錄", comment: "Save layout")
            return cell
        } else {
            let keys = themes.keys.sorted { $0 == currentDeviceName || $0 > $1 }
            let key = keys[keys.index(keys.startIndex, offsetBy: indexPath.section - 1)]
            let cell = tableView.dequeueReusableCell(withIdentifier: ThemeCell.identifier, for: indexPath) as! ThemeCell
            if let theme = themes[key]?[indexPath.row] {
                cell.title = theme.name
                cell.date = theme.modifiedDate
                cell.deviceName = theme.deviceName
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return .insert
        } else {
            return .delete
        }
    }
    
    // Select
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section > 0 {
            let cell = (tableView.cellForRow(at: indexPath) as! ThemeCell)
            
            let alertController = UIAlertController(title: NSLocalizedString("換主題", comment: "Confirm to select theme title"), message: NSLocalizedString("換爲：", comment: "Confirm to select theme message") + (cell.title ?? ""), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("容吾三思", comment: "Cancel Resetting Settings"), style: .default)
            let confirmAction = UIAlertAction(title: NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), style: .destructive) {[self] _ in
                DataContainer.shared.loadSave(name: cell.title, deviceName: cell.deviceName)
                WatchFaceView.currentInstance?.drawView(forceRefresh: true)
                (navigationController?.viewControllers.first as? SettingsViewController)?.reload()
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
            
            DataContainer.shared.loadSave(name: cell.title, deviceName: cell.deviceName)

        // New
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("取名", comment: "set a name"), message: NSLocalizedString("不得爲空，不得重名", comment: "no blank, no duplicate name"), preferredStyle: .alert)
            let addNewAction = UIAlertAction(title: NSLocalizedString("此名甚善", comment: "Confirm adding Settings"), style: .default) { _ in
                DataContainer.shared.saveLayout(WatchLayout.shared.encode(), name: alertController.textFields![0].text)
                self.refresh()
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("容吾三思", comment: "Cancel adding Settings"), style: .default)
            alertController.addTextField { [self] textField in
                textField.text = generateNewName(baseName: NSLocalizedString("無名", comment: "new theme default name"))
                textField.addTarget(self, action: #selector(self.validateName(_:)), for: .editingChanged)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(addNewAction)
            alertController.actions[1].isEnabled = false
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func generateNewName(baseName: String) -> String {
        var newFileName = baseName
        guard let currentDeviceThemes = (themes[currentDeviceName]?.map { $0.name }) else { return baseName }
        var i = 2
        while currentDeviceThemes.contains(newFileName) {
            newFileName = baseName + " \(i)"
            i += 1
        }
        return newFileName
    }
    
    @objc func validateName(_ sender: UITextField) {
        var resp : UIResponder! = sender
        while !(resp is UIAlertController) { resp = resp.next }
        let alert = resp as! UIAlertController
        if let fileName = sender.text, fileName != "" {
            let currentDeviceThemes = themes[currentDeviceName]
            if currentDeviceThemes == nil || !(currentDeviceThemes!.map { $0.name }.contains(fileName)) {
                alert.actions[1].isEnabled = true
                return
            }
        }
        alert.actions[1].isEnabled = false
        return
    }
    
    // Delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cell = (tableView.cellForRow(at: indexPath) as! ThemeCell)
            
            let alertController = UIAlertController(title: NSLocalizedString("刪主題", comment: "Confirm to delete theme title"), message: NSLocalizedString("刪：", comment: "Confirm to delete theme message") + (cell.title ?? ""), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("容吾三思", comment: "Cancel Resetting Settings"), style: .default)
            let confirmAction = UIAlertAction(title: NSLocalizedString("吾意已決", comment: "Confirm Resetting Settings"), style: .destructive) {_ in
                DataContainer.shared.deleteSave(name: cell.title!, deviceName: cell.deviceName!)
                self.loadThemes()
                self.tableView.reloadData()
            }

            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        }
    }
}
