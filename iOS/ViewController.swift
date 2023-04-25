//
//  ViewController.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/17/23.
//

import UIKit

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
        longPressGesture.minimumPressDuration = 1.0
        longPressGesture.delegate = self
        watchFace!.addGestureRecognizer(longPressGesture)

        // Do any additional setup after loading the view.
    }
    
    @objc func longPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let settingsViewController = storyBoard.instantiateViewController(withIdentifier: "Settings") as! UINavigationController
            self.present(settingsViewController, animated:true, completion:nil)
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
    var tableViewController: UITableViewController?
    var nextView: UIViewController?
    var desp1: String?
    var desp2: String?
    var option1: String?
    var option2: String?
    var selection: Int?
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
        
        if nextView != nil {
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
        } else {
            if let option1 = self.option1, let option2 = self.option2, let selection = self.selection {
                segment = UISegmentedControl(items: [option1, option2])
                segment!.frame = CGRect(x: CGRectGetMaxX(label.frame) + 15, y: (bounds.height - labelSize.height * 1.6) / 2, width: bounds.width - CGRectGetMaxX(label.frame) - 30, height: labelSize.height * 1.6)
                segment!.selectedSegmentIndex = selection
                self.addSubview(segment!)
            }
        }
        self.addSubview(elements)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
        tableViewController = nil
        nextView = nil
        desp1 = nil
        desp2 = nil
        option1 = nil
        option2 = nil
        selection = nil
    }
    
    @objc func cellTapped(sender: Any?) {
        if let nextView = self.nextView {
            tableViewController?.navigationController?.pushViewController(nextView, animated: true)
        }
    }
}

struct DuelOption {
    let title: String
    let firstOption: String
    let secondOption: String
    let selection: Int
}
struct DetailOption {
    let title: String
    let nextView: UIViewController?
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
    
    func coordinateDesp(coordinate: CGPoint) -> (String, String) {
        var latitude = coordinate.x
        var latitudeLabel = ""
        if latitude > 0 {
            latitudeLabel = "N"
        } else if latitude < 0 {
            latitudeLabel = "S"
        }
        var latitudeString = ""
        latitude = abs(latitude)
        latitudeString += String(format: "%.0f", latitude) + "°"
        latitude = (latitude - floor(latitude)) * 60
        latitudeString += String(format: "%.0f", latitude) + "\'"
        latitude = (latitude - floor(latitude)) * 60
        latitudeString += String(format: "%.1f", latitude) + "\""
        latitudeString += " \(latitudeLabel)"
        
        var longitude = coordinate.y
        var longitudeLabel = ""
        if longitude > 0 {
            longitudeLabel = "E"
        } else if longitude < 0 {
            longitudeLabel = "W"
        }
        var longitudeString = ""
        longitude = abs(longitude)
        longitudeString += String(format: "%.0f", longitude) + "°"
        longitude = (longitude - floor(longitude)) * 60
        longitudeString += String(format: "%.0f", longitude) + "\'"
        longitude = (longitude - floor(longitude)) * 60
        longitudeString += String(format: "%.1f", longitude) + "\""
        longitudeString += " \(longitudeLabel)"
        
        return (latitudeString, longitudeString)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.register(TableCell.self, forCellReuseIdentifier: TableCell.identifier)
        tableView.rowHeight = 66
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let time = WatchFaceView.currentInstance?.displayTime ?? Date()
        let timezone = WatchFaceView.currentInstance?.timezone ?? Calendar.current.timeZone
        let locationString = WatchFaceView.currentInstance?.location.map { coordinateDesp(coordinate: $0) }
        let datetime = DetailOption(title: "顯示時間", nextView: storyboard.instantiateViewController(withIdentifier: "DateTime"),
                                    desp1: time.formatted(date: .abbreviated, time: .shortened), desp2: timezone.identifier)
        let location = DetailOption(title: "經緯度", nextView: storyboard.instantiateViewController(withIdentifier: "Location"),
                                      desp1: locationString?.0, desp2: locationString?.1)
        let leapMonth = DuelOption(title: "置閏法", firstOption: "精確至時刻", secondOption: "精確至日", selection: ChineseCalendar.globalMonth ? 0 : 1)
        let apparantDay = DuelOption(title: "時間", firstOption: "真太陽時", secondOption: "標準時", selection: ChineseCalendar.apparentTime ? 0 : 1)
        models = [
            Section(title: "數據", options: [.dual(model: leapMonth), .dual(model: apparantDay), .detail(model: datetime) , .detail(model: location)]),
            Section(title: "樣式", options: [.detail(model: DetailOption(title: "圈色", nextView: nil, desp1: nil, desp2: nil)),
                                            .detail(model: DetailOption(title: "塊標色", nextView: nil, desp1: nil, desp2: nil)),
                                            .detail(model: DetailOption(title: "佈局", nextView: nil, desp1: nil, desp2: nil))])
        ]
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
            cell.tableViewController = self
            if let nextView = model.nextView {
                cell.nextView = nextView
                let recognizer = UITapGestureRecognizer(target: cell, action: #selector(TableCell.cellTapped(sender:)))
                cell.addGestureRecognizer(recognizer)
            }
        case.dual(model: let model):
            cell.title = model.title
            cell.option1 = model.firstOption
            cell.option2 = model.secondOption
            cell.selection = model.selection
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
