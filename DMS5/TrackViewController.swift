//
//  TrackViewController.swift
//  DMS5
//
//  Created by 黄 康平 on 8/7/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON
import WWCalendarTimeSelector

class TrackViewController: UIViewController, GMSMapViewDelegate, WWCalendarTimeSelectorProtocol{
    @IBOutlet weak var infoView: UIScrollView!
    @IBOutlet weak var distanceImage: UIImageView!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var rateImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var eventView: UIView!
    @IBOutlet weak var rateView: UIView!
    
    var mapView = GMSMapView()
    var timer: Timer!
    var i: UInt = 0
    var animationPolyline = GMSPolyline()
    var animationPath = GMSMutablePath()
    var mvc = MapViewController()
    var timeDifference: Int!
    var eventsList =  [Int: (CLLocationCoordinate2D, String)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let hashVehicleInfo: [String: Any] = ["vid": selectedVehicleId, "dat": mvc.todayDate()]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sendEventRequestNotification"), object: nil, userInfo: hashVehicleInfo)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateEvent(_:)),name:NSNotification.Name(rawValue: "updateEventNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateCompound(_:)),name:NSNotification.Name(rawValue: "updateCompoundNotification"), object: nil)
        let navigationBar = self.navigationController?.navigationBar
        let navigationItem = self.navigationItem
        navigationBar?.isTranslucent = false
        navigationBar?.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationBar?.shadowImage = UIImage()
        
        infoView.frame = CGRect(x: 0, y: UIImage().size.height, width: view.frame.size.width, height: 30)
        let infoImageSize = CGRect(x: 10, y: UIImage().size.height+1, width: 25, height: 25)
        let infoLabelSize = CGRect(x: 40, y: UIImage().size.height+1, width:50, height: 25)
        
        distanceView.frame = CGRect(x: 10, y: UIImage().size.height, width: 90, height: 27)
        distanceImage.frame = infoImageSize
        distanceLabel.frame = infoLabelSize
        distanceView.layer.cornerRadius = 13.5
        distanceView.layer.masksToBounds = true
        distanceLabel.text = "\((Vehicles[selectedVehicleId]?.distance)!) km"
        
        eventView.frame = CGRect(x: 105, y: UIImage().size.height, width: 100, height: 27)
        eventImage.frame = infoImageSize
        eventLabel.frame = infoLabelSize
        eventView.layer.cornerRadius = 13.5
        eventView.layer.masksToBounds = true
        eventLabel.text = "\((Vehicles[selectedVehicleId]?.eventsNo)!) events"
        
        rateView.frame = CGRect(x: 210, y: UIImage().size.height, width: 90, height: 27)
        rateImage.frame = infoImageSize
        rateLabel.frame = infoLabelSize
        rateView.layer.cornerRadius = 13.5
        rateView.layer.masksToBounds = true
        rateLabel.text = "\(Double(selectedScore)/10.0)/10"
        
        let distanceViewGesture = UITapGestureRecognizer(target: self, action:  #selector (self.distanceTapped(_:)))
        self.distanceView.addGestureRecognizer(distanceViewGesture)
        let eventViewGesture = UITapGestureRecognizer(target: self, action:  #selector (self.eventTapped(_:)))
        self.eventView.addGestureRecognizer(eventViewGesture)
        let rateViewGesture = UITapGestureRecognizer(target: self, action:  #selector (self.rateTapped(_:)))
        self.rateView.addGestureRecognizer(rateViewGesture)
        distanceViewTapped()
        
        navigationBar?.barTintColor = UIColor(hex: "F1F8E9")
        navigationBar?.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "back").resizedImageWithinRect(rectSize: CGSize(width: 20, height: 20)), style: .plain, target: self, action: #selector(backAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "setting").resizedImageWithinRect(rectSize: CGSize(width: 25, height: 25)), style: .plain, target: self, action: #selector(showCalendar))
        self.title = "\(selectedVehicleNo!)'s Track"
        
        mapView.delegate = self
        if trackPositions.isEmpty != true{
            let sortedTrackPositions = trackPositions.sorted{ $0.key < $1.key }
            drawAllPath(positions: sortedTrackPositions)
            drawPath(position1: (sortedTrackPositions.last?.value.0)!, position2: CLLocationCoordinate2D(latitude: (Vehicles[selectedVehicleId]?.vehiclePosition.0)!, longitude: (Vehicles[selectedVehicleId]?.vehiclePosition.1)!), isLastPosition: true)
            timeDifference = ((Vehicles[selectedVehicleId]?.time)! - (sortedTrackPositions.last?.key)!)/100
        }
        else{
            let camera = GMSCameraPosition.camera(withLatitude: (Vehicles[selectedVehicleId]?.vehiclePosition.0)!, longitude: (Vehicles[selectedVehicleId]?.vehiclePosition.1)!, zoom: 12.0)
            mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), camera: camera)
            self.view.addSubview(mapView)
            self.view.bringSubview(toFront: infoView)
        }
        setLastMarker(position: CLLocationCoordinate2D(latitude: (Vehicles[selectedVehicleId]?.vehiclePosition.0)!, longitude: (Vehicles[selectedVehicleId]?.vehiclePosition.1)!), heading: (Vehicles[selectedVehicleId]?.vehicleHeading)!, time: (Vehicles[selectedVehicleId]?.time)!)
        
        //drawPath(position1: CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717), position2: CLLocationCoordinate2D(latitude: -38.036960, longitude: 145.192215))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showCalendar() {
        isTrackingHistory = true
        let selector = UIStoryboard(name: "WWCalendarTimeSelector", bundle: nil).instantiateInitialViewController() as! WWCalendarTimeSelector
        selector.delegate = self
        selector.optionStyles.showDateMonth(true)
        selector.optionStyles.showMonth(false)
        selector.optionStyles.showYear(true)
        selector.optionStyles.showTime(false)
        present(selector, animated: true, completion: nil)
    }
    
    func WWCalendarTimeSelectorDone(_ selector: WWCalendarTimeSelector, date: Date) {
        print("Selected \n\(date)\n---")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let convertedDate = dateFormatter.string(from: date)
        let selectedDate = Int(convertedDate)!
        let hashVehicleInfo: [String: Any] = ["vid": selectedVehicleId, "dat": selectedDate]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sendCompoundRequestNotification"), object: nil, userInfo: hashVehicleInfo)
    }
    
    func distanceTapped(_ sender:UITapGestureRecognizer){
        distanceViewTapped()
        eventViewUntapped()
        rateViewUntapped()
    }
    
    func eventTapped(_ sender:UITapGestureRecognizer){
        eventViewTapped()
        distanceViewUntapped()
        rateViewUntapped()
    }
    
    func rateTapped(_ sender:UITapGestureRecognizer){
        rateViewTapped()
        distanceViewUntapped()
        eventViewUntapped()
    }
    
    func distanceViewTapped(){
        distanceView.backgroundColor = UIColor.darkGray
        distanceImage.image = #imageLiteral(resourceName: "cartrackTapped")
        distanceLabel.textColor = UIColor(hex: "F1F8E9")
    }
    
    func eventViewTapped(){
        eventView.backgroundColor = UIColor.darkGray
        eventImage.image = #imageLiteral(resourceName: "careventTapped")
        eventLabel.textColor = UIColor(hex: "F1F8E9")
    }
    
    func rateViewTapped(){
        rateView.backgroundColor = UIColor.darkGray
        rateImage.image = #imageLiteral(resourceName: "carrateTapped")
        rateLabel.textColor = UIColor(hex: "F1F8E9")
    }
    
    func distanceViewUntapped(){
        distanceView.backgroundColor = UIColor.clear
        distanceImage.image = #imageLiteral(resourceName: "cartrack")
        distanceLabel.textColor = UIColor.darkGray
    }
    
    func eventViewUntapped(){
        eventView.backgroundColor = UIColor.clear
        eventImage.image = #imageLiteral(resourceName: "carevent")
        eventLabel.textColor = UIColor.darkGray
    }
    
    func rateViewUntapped(){
        rateView.backgroundColor = UIColor.clear
        rateImage.image = #imageLiteral(resourceName: "carrate")
        rateLabel.textColor = UIColor.darkGray
    }
    
    func backAction(){
        self.performSegue(withIdentifier: "toCvc", sender: self)
        isTrackingHistory = false
    }
    
    func updateEvent(_ notification: NSNotification){
        if let events = notification.object as? [Int: (CLLocationCoordinate2D, String)]{
            eventsList = events
            for event in events{
                if event.value.1 == "SpdOver"{
                    setEventMarker(position: event.value.0, time: event.key, type: "SpdOver", icon: #imageLiteral(resourceName: "overspeed"))
                } else if event.value.1 == "Geofence"{
                    setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "geofence"))
                } else{
                    setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "warn"))
                }
            }
        }
    }
    
    func updateCompound(_ notification: NSNotification){
        mapView.clear()
        
        distanceLabel.text = "\((Vehicles[selectedVehicleId]?.distance)!) km"
        eventLabel.text = "\((Vehicles[selectedVehicleId]?.eventsNo)!) events"
        rateLabel.text = "\(Double(selectedScore)/10.0)/10"
        
        for event in eventsList{
            if event.value.1 == "SpdOver"{
                setEventMarker(position: event.value.0, time: event.key, type: "SpdOver", icon: #imageLiteral(resourceName: "overspeed"))
            } else if event.value.1 == "Geofence"{
                setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "geofence"))
            } else{
                setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "warn"))
            }
        }
        
        let sortedTrackPositions = trackPositions.sorted{ $0.key < $1.key }
        drawAllPath(positions: sortedTrackPositions)
        drawPath(position1: (sortedTrackPositions.last?.value.0)!, position2: CLLocationCoordinate2D(latitude: (Vehicles[selectedVehicleId]?.vehiclePosition.0)!, longitude: (Vehicles[selectedVehicleId]?.vehiclePosition.1)!), isLastPosition: true)
        timeDifference = ((Vehicles[selectedVehicleId]?.time)! - (sortedTrackPositions.last?.key)!)/100
        
        setLastMarker(position: CLLocationCoordinate2D(latitude: (Vehicles[selectedVehicleId]?.vehiclePosition.0)!, longitude: (Vehicles[selectedVehicleId]?.vehiclePosition.1)!), heading: (Vehicles[selectedVehicleId]?.vehicleHeading)!, time: (Vehicles[selectedVehicleId]?.time)!)
    }
    
    func timeToString(time: Int) -> String{
        let hour: Int = time/10000
        let minute: Int = time/100 - hour*100
        return String(format: "%02d:%02d", hour, minute)
    }
    
    func setEventMarker(position: CLLocationCoordinate2D, time: Int, type: String, icon: UIImage){
        let marker = GMSMarker()
        if icon == #imageLiteral(resourceName: "geofence"){
            marker.icon = mvc.imageWithImage(image: icon, scaledToSize: CGSize(width: 30, height:30))
        }else{
            marker.icon = mvc.imageWithImage(image: icon, scaledToSize: CGSize(width: 20, height:20))
        }
        marker.position = position
        marker.title = timeToString(time: time)
        marker.snippet = type
        marker.map = mapView
    }
    
    func setMarker(position: CLLocationCoordinate2D, heading: Int, time: Int){
        let marker = GMSMarker()
        marker.icon = mvc.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 17.5, height: 8.5)).alpha(0.3)
        marker.position = position
        marker.title = timeToString(time: time)
        marker.rotation = CDouble(heading+90)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.map = mapView
    }
    
    func setLastMarker(position: CLLocationCoordinate2D, heading: Int, time: Int){
        let marker = GMSMarker()
        marker.icon = mvc.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 17.5, height:8.5))
        marker.position = position
        marker.title = timeToString(time: time)
        marker.rotation = CDouble(heading+90)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.map = mapView
    }
    
    func drawAllPath(positions: [(key: Int, value: (CLLocationCoordinate2D, Int))]){
        var twoPositions = [CLLocationCoordinate2D?](repeating: nil, count: 2)
        for position in positions{
            setMarker(position: position.value.0, heading: position.value.1, time: position.key)
            if twoPositions[1] == nil{
                let camera = GMSCameraPosition.camera(withLatitude: position.value.0.latitude, longitude: position.value.0.longitude, zoom: 12.0)
                mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), camera: camera)
                self.view.addSubview(mapView)
                self.view.bringSubview(toFront: infoView)
                twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
            }
            else{
                twoPositions[0] = twoPositions[1]
                twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
                drawPath(position1: twoPositions[0]!, position2: twoPositions[1]!, isLastPosition: false)
            }
        }
    }
    
    func drawPath(position1: CLLocationCoordinate2D, position2: CLLocationCoordinate2D, isLastPosition: Bool)
    {
        let origin = "\(position1.latitude),\(position1.longitude)"
        let destination = "\(position2.latitude),\(position2.longitude)"
        
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyBFTEmpETJFA_eg-eUn5IBEM1mkf50wwRo"
        
        Alamofire.request(url).responseJSON { response in
            print(response.request)  // original URL request
            print(response.response) // HTTP URL response
            print(response.data)     // server data
            print(response.result)   // result of response serialization
            
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            for route in routes
            {
                var polyline: GMSPolyline
                let routelegs = route["legs"].arrayValue
                for routeleg in routelegs{
                    let distance = routeleg["distance"].dictionary
                    let meters = distance?["value"]?.intValue
                    if ((!isLastPosition) && meters! > 2000) || (isLastPosition && meters! > 2000*self.timeDifference){
                        let path = GMSMutablePath()
                        path.add(position1)
                        path.add(position2)
                        polyline = GMSPolyline(path: path)
                    }
                    else{
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points = routeOverviewPolyline?["points"]?.stringValue
                        let path = GMSPath(fromEncodedPath: points!)
                        polyline = GMSPolyline(path: path)
                        //self.timer = Timer.scheduledTimer(timeInterval: 0.003, target: self, selector: #selector(self.animatePolylinePath), userInfo: path, repeats: true)
                    }
                    polyline.strokeWidth = 3.0
                    polyline.strokeColor = UIColor(hex: "14A1FC")
                    polyline.map = self.mapView
                }
            }
        }
    }
}


