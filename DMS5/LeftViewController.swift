//
//  LeftViewController.swift
//  SlideMenuControllerSwift
//
//  Created by Yuji Hato on 12/3/14.
//

import UIKit

enum LeftMenu: Int {
//    case main = 0
    case track
    case java
    case go
    case nonMenu
}

protocol LeftMenuProtocol : class {
    func changeViewController(_ menu: LeftMenu)
}

class LeftViewController : UIViewController, LeftMenuProtocol {
    /// Return the number of rows in each component.
    @IBOutlet weak var tableView: UITableView!
    var menus = ["Track", "Events", "Report"]
    var mainViewController: UIViewController!
    var trackViewController: UIViewController!
    var javaViewController: UIViewController!
    var goViewController: UIViewController!
    var nonMenuViewController: UIViewController!
    var imageHeaderView: ImageHeaderView!
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStarView(_:)),name:NSNotification.Name(rawValue: "updateScoreNotification"), object: nil)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let trackViewController = storyboard.instantiateViewController(withIdentifier: "TrackViewController") as! TrackViewController
        self.trackViewController = UINavigationController(rootViewController: trackViewController)
        self.tableView.separatorColor = UIColor.clear
        self.tableView.registerCellClass(BaseTableViewCell.self)
        self.imageHeaderView = ImageHeaderView.loadNib()
        self.view.addSubview(self.imageHeaderView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.imageHeaderView.selectedVehicles.removeAll()
        for vehicle in Vehicles{
            self.imageHeaderView.selectedVehicles.append(vehicle.value.vehicleNo)
            self.imageHeaderView.selectedDrivers.append(vehicle.value.driverName)
            self.imageHeaderView.selectedVehicleIds.append(vehicle.key)
        }
        self.imageHeaderView.dropdownMenu.reloadAllComponents()
        if let vehicleNo = selectedVehicleNo{
            self.imageHeaderView.vehicleLabel.text = vehicleNo
            if let driver = selectedDriver{
                self.imageHeaderView.vehicleLabel.text = "\(driver)'s \(vehicleNo)"
            }
            self.imageHeaderView.starView.rating = Double(selectedScore)/20.0
            self.imageHeaderView.starView.text = "\(Double(selectedScore)/10.0)/10"
            self.imageHeaderView.starView.isHidden = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.imageHeaderView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 160)
        
        self.view.layoutIfNeeded()
    }
    
    func updateStarView(_ notification: NSNotification) {
        self.imageHeaderView.starView.rating = Double(selectedScore)/20.0
        self.imageHeaderView.starView.text = "\(Double(selectedScore)/10.0)/10"
        self.imageHeaderView.starView.isHidden = false
    }
    
    func changeViewController(_ menu: LeftMenu) {
        switch menu {
//        case .main:
//            self.slideMenuController()?.changeMainViewController(self.mainViewController, close: true)
        case .track:
            self.slideMenuController()?.changeMainViewController(self.trackViewController, close: true)
        case .java: break
            //self.slideMenuController()?.changeMainViewController(self.javaViewController, close: true)
        case .go: break
            //self.slideMenuController()?.changeMainViewController(self.goViewController, close: true)
        case .nonMenu: break
            //self.slideMenuController()?.changeMainViewController(self.nonMenuViewController, close: true)
        }
    }
}

extension LeftViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let menu = LeftMenu(rawValue: indexPath.row) {
            switch menu {
            case .track, .java, .go, .nonMenu:
                return BaseTableViewCell.height()
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let menu = LeftMenu(rawValue: indexPath.row) {
            self.changeViewController(menu)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView == scrollView {
            
        }
    }
}

extension LeftViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let menu = LeftMenu(rawValue: indexPath.row) {
            switch menu {
            case .track, .java, .go, .nonMenu:
                let cell = BaseTableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: BaseTableViewCell.identifier)
                cell.setData(menus[indexPath.row])
                return cell
            }
        }
        return UITableViewCell()
    }
    
    
}
