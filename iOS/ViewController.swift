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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let label = UILabel()
        let labelSize = CGSize(width: 100, height: 21)
        label.frame = CGRect(x: 30, y: (bounds.height - labelSize.height) / 2, width: labelSize.width, height: labelSize.height)
        label.text = title
        self.addSubview(label)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
    }
    
    @objc func cellTapped(sender: Any?) {
        if let nextView = self.nextView {
            tableViewController?.navigationController?.pushViewController(nextView, animated: true)
        }
    }
}

struct SettingsOption {
    let title: String
    let nextView: UIViewController?
}

class SettingsViewController: UITableViewController {
    var models = [SettingsOption]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TableCell.self, forCellReuseIdentifier: TableCell.identifier)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        models = [
            SettingsOption(title: "顯示時間", nextView: storyboard.instantiateViewController(withIdentifier: "DateTime")),
            SettingsOption(title: "經緯度", nextView: storyboard.instantiateViewController(withIdentifier: "Location"))
        ]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TableCell.identifier, for: indexPath) as! TableCell
        cell.title = model.title
        cell.tableViewController = self
        if let nextView = model.nextView {
            cell.nextView = nextView
            let recognizer = UITapGestureRecognizer(target: cell, action: #selector(TableCell.cellTapped(sender:)))
            cell.addGestureRecognizer(recognizer)
        }
        return cell
    }
}
