
import UIKit

var selectedVehicleId: String!

class ImageHeaderView : UIView, MKDropdownMenuDelegate, MKDropdownMenuDataSource {
    
    @IBOutlet weak var profileImage : UIImageView!
    @IBOutlet weak var backgroundImage : UIImageView!
    @IBOutlet weak var vehicleLabel: UILabel!
    @IBOutlet weak var starView: CosmosView!
    @IBOutlet weak var dropdownMenu: MKDropdownMenu!
    var selectedVehicles: [String] = []
    var selectedDrivers: [String] = []
    var selectedVehicleIds: [String] = []
    
    override func awakeFromNib() {
        let settingImage = #imageLiteral(resourceName: "setting").resizedImageWithinRect(rectSize: CGSize(width: 30, height: 30))
        dropdownMenu.disclosureIndicatorImage = settingImage
        dropdownMenu.delegate = self
        dropdownMenu.dataSource = self
        dropdownMenu.backgroundDimmingOpacity = 0
        super.awakeFromNib()
        self.starView.frame = CGRect(x: 16, y: 95, width: 50, height: 20)
        self.starView.settings.fillMode = .precise
        self.backgroundColor = UIColor.white
        self.profileImage.layoutIfNeeded()
        self.profileImage.layer.cornerRadius = self.profileImage.bounds.size.height / 2
        self.profileImage.clipsToBounds = true
        self.profileImage.layer.borderWidth = 1
        self.profileImage.layer.borderColor = UIColor.white.cgColor
        //self.profileImage.setRandomDownloadImage(80, height: 80)
        self.profileImage.image = #imageLiteral(resourceName: "truck")
        self.profileImage.contentMode = .scaleAspectFit
        //self.backgroundImage.setRandomDownloadImage(Int(self.bounds.size.width), height: 160)
        vehicleLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 20.0)
    }
    
    func numberOfComponents(in dropdownMenu: MKDropdownMenu) -> Int {
        return 1
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: selectedVehicles[row], attributes: [NSForegroundColorAttributeName: UIColor.black])
        return attributedString
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, didSelectRow row: Int, inComponent component: Int) {
        let hashVehicleId: [String: String] = ["vid": selectedVehicleIds[row]]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sendScoreRequestNotification"), object: nil, userInfo: hashVehicleId)
        selectedVehicleId = selectedVehicleIds[row]
        selectedVehicleNo = selectedVehicles[row]
        selectedDriver = selectedDrivers[row]
        vehicleLabel.text = "\(selectedDrivers[row])'s \(selectedVehicles[row])"
        dropdownMenu.closeAllComponents(animated: true)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, numberOfRowsInComponent component: Int) -> Int {
        return selectedVehicles.count
    }
}
