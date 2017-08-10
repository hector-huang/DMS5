//
//  MapViewController.swift
//  DMS5
//
//  Created by 黄 康平 on 5/26/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import GoogleMaps
import Starscream

var selectedVehicleNo: String!
var selectedDriver: String!
var selectedScore: Int!
var Vehicles = [String: (driverName:String, vehicleNo:String, vehiclePosition: (Double, Double), vehicleHeading: Int, time: Int, eventsNo: Int, distance: Int)]()
var trackPositions = [Int: (CLLocationCoordinate2D, Int)]()
var isTrackingHistory = false

class MapViewController: UIViewController, WebSocketDelegate, GMSMapViewDelegate {
    @IBOutlet weak var menu: UIButton!
    @IBOutlet weak var camera: UIButton!
    var selectedTime: Int!
    var circle: UIView!
    var updateMapViewTimer: Timer!
    var mainUrl = "http://120.146.195.80:100"
    var socket = WebSocket(url: URL(string:"ws://120.146.195.80:100/ws")!)
    var vc = ViewController()
    var mapView = GMSMapView()
    var isFirstTracklistRPS = true
    var positions = [String: CLLocationCoordinate2D]()
    var imageHeader = ImageHeaderView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.writeScoreRequest(_:)),name:NSNotification.Name(rawValue: "sendScoreRequestNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.writeEventRequest(_:)),name:NSNotification.Name(rawValue: "sendEventRequestNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.writeCompoundRequest(_:)),name:NSNotification.Name(rawValue: "sendCompoundRequestNotification"), object: nil)
        
        camera.frame = CGRect(x: view.frame.width-47, y: 35, width: 37, height: 27)
        menu.frame = CGRect(x: 16, y: 35, width: 37, height: 27)
        camera.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        menu.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        camera.addTarget(self, action: #selector(cameraTapped(_:)), for: .touchUpInside)
        menu.addTarget(self, action: #selector(toggleLeft), for: .touchUpInside)
        
        //NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        circle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        circle.backgroundColor = UIColor.clear
        circle.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "circle"))
        circle.contentMode = UIViewContentMode.scaleAspectFill
//        circle.layer.borderColor = UIColor(red: 53/255, green: 145/255, blue: 195/255, alpha: 1.0).cgColor
//        circle.layer.borderWidth = 1
//        circle.layer.cornerRadius = 50
        startTimer()
        socket.delegate = self
        socket.connect()
        print("viewloaded!")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func resetMapCenter(vehicleId: String) {
        if let latitude = positions[vehicleId]?.latitude, let longtitude = positions[vehicleId]?.longitude{
            if latitude != 0 {
                let updatedCamera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longtitude, zoom: 15.0)
                mapView.animate(to: updatedCamera)
            }
        }
    }
    
    func writeScoreRequest(_ notification: NSNotification) {
        if let vehicleId = notification.userInfo?["vid"] as? String {
            writeVehicleTrackRequest(vehicleId: vehicleId, date: todayDate())
            resetMapCenter(vehicleId: vehicleId)
        }
    }
    
    func writeEventRequest(_ notification: NSNotification) {
        if let vehicleId = notification.userInfo?["vid"] as? String, let date = notification.userInfo?["dat"] as? Int {
            writeVehicleEventRequest(vehicleId: vehicleId, date: date)
        }
    }
    
    func writeCompoundRequest(_ notification: NSNotification) {
        if let vehicleId = notification.userInfo?["vid"] as? String, let date = notification.userInfo?["dat"] as? Int {
            writeVehicleTrackRequest(vehicleId: vehicleId, date: date)
            writeVehicleEventRequest(vehicleId: vehicleId, date: date)
            writeTracklistRequest(date: date)
        }
    }

    
    func initializeVehicleArray(vehiclesInfo: [(driverName: String, vehicleNo: String, vehicleId: String, vehiclePosition: (Double, Double), vehicleHeading: Int, time: Int, eventsNo: Int, distance: Int)]){
        for vehicleInfo in vehiclesInfo{
            Vehicles[vehicleInfo.vehicleId] = (vehicleInfo.driverName, vehicleInfo.vehicleNo, (vehicleInfo.vehiclePosition.0, vehicleInfo.vehiclePosition.1), vehicleInfo.vehicleHeading, vehicleInfo.time, vehicleInfo.eventsNo, vehicleInfo.distance)
        }
    }
    
    func updateVehicleArray(vehicleId: String, time: Int, eventsNo: Int, distance: Int){
        Vehicles[vehicleId]?.time = time
        Vehicles[vehicleId]?.eventsNo = eventsNo
        Vehicles[vehicleId]?.distance = distance
    }
    
    func startTimer() {
        self.updateMapViewTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(writeTracklistRequest), userInfo: nil, repeats: true)
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        circle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        circle.backgroundColor = UIColor.clear
        circle.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "circle"))
        circle.contentMode = UIViewContentMode.scaleAspectFill
        //        circle.layer.borderColor = UIColor(red: 53/255, green: 145/255, blue: 195/255, alpha: 1.0).cgColor
        startTimer()
        socket.delegate = self
        socket.connect()
        print("foregroundentered!")
    }
    
    func applicationDidEnterForeground(notification: NSNotification) {
        self.updateMapViewTimer.invalidate()
        mapView.clear()
        positions.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func cameraTapped(_ sender: AnyObject?) {
        //socket.write(string: "{\"cmd\": \"CMD_LIVESNAPSHOT\", \"vid\": \"\(selectedVehicleId!)\"}")
        selectedTime = todayTime()-20
        socket.write(string: "{\"cmd\":\"CMD_REQUESTMDT\",\"vid\":\"\(selectedVehicleId!)\",\"dat\":\(todayDate()),\"tim\":\(selectedTime!),\"pre\":0,\"post\":5,\"vch\":1}")
        print("{\"cmd\":\"CMD_REQUESTMDT\",\"vid\":\"\(selectedVehicleId!)\",\"dat\":\(todayDate()),\"tim\":\(selectedTime!),\"pre\":0,\"post\":5,\"vch\":1}")
//        let when = DispatchTime.now() + 20 // change 2 to desired number of seconds
//        DispatchQueue.main.asyncAfter(deadline: when) {
//            let url: String = "\(self.mainUrl)/VEHICLE/\(self.selectedVehicleId!)/\(self.todayYear())/\(self.todayMonth())/\(self.todayDay())/MP4/\(self.todayDate())_\(self.selectedTime!)_ch1_5.MP4"
//            print(url)
//            self.videoPlay(url: url)
//        }
    }
    
    func initiateMapView(cameraLocation: (latitude: Double, longitude: Double), markersInfo: [(latitude: Double, longtitude: Double, heading: Int, driverName: String, vehicleNo: String, status: Int, deviceNo: String, vehicleID: String)]){
        let camera = GMSCameraPosition.camera(withLatitude: cameraLocation.latitude, longitude: cameraLocation.longitude, zoom: 12.0)
        mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), camera: camera)
        mapView.delegate = self
        self.view.addSubview(mapView)
        updateMapView(markersInfo: markersInfo)
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        camera.isHidden = true
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        selectedVehicleId = marker.userData as! String!
        if let requestVehicleId = marker.userData as? String{
            writeVehicleTrackRequest(vehicleId: requestVehicleId, date: todayDate())
        }
        selectedVehicleNo = marker.snippet as String!
        selectedDriver = marker.title as String!
        camera.isHidden = false
        mapView.selectedMarker = marker
        return true
    }
    
    func updateMapView(markersInfo: [(latitude: Double, longtitude: Double, heading: Int, driverName: String, vehicleNo: String, status: Int, deviceNo: String, vehicleID: String)]){
        for markerInfo in markersInfo {
//            if markerInfo.vehicleNo == "TX4000-Test"{
//                print("Hector is online")
//                if positions[markerInfo.vehicleID]?.latitude == -38.036259{
//                    animateMoveMarker(oldPosition: CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717), newPosition: CLLocationCoordinate2D(latitude: -38.036960, longitude: 145.192215), heading: 90, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, mapView: mapView)
//                    animateMovePulseMarker(oldPosition: CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717), newPosition: CLLocationCoordinate2D(latitude: -38.036960, longitude: 145.192215), heading: 90, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, mapView: mapView)
//                }
//                else{
//                animateMoveMarker(oldPosition: CLLocationCoordinate2D(latitude: -38.041405, longitude: 145.187248), newPosition: CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717), heading: 90, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, mapView: mapView)
//                animateMovePulseMarker(oldPosition: CLLocationCoordinate2D(latitude: -38.041405, longitude: 145.187248), newPosition: CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717), heading: 90, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, mapView: mapView)
//                positions[markerInfo.vehicleID] = CLLocationCoordinate2D(latitude: -38.036259, longitude: 145.188717)
//                }
//            }
            
            
            if markerInfo.status == 0{
                setMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo, markerInfo.vehicleID), mapView: mapView)
                //setPulseMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo), mapView: mapView)
                positions[markerInfo.vehicleID] = CLLocationCoordinate2D(latitude: markerInfo.latitude, longitude: markerInfo.longtitude)
            }
            else{
                if let position = positions[markerInfo.vehicleID] {
                    if position.latitude != markerInfo.latitude && position.longitude != markerInfo.longtitude {
                        animateMoveMarker(oldPosition: position, newPosition: CLLocationCoordinate2D(latitude: markerInfo.latitude, longitude: markerInfo.longtitude), heading: markerInfo.heading, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, vehicleID: markerInfo.vehicleID, mapView: mapView)
                        animateMovePulseMarker(oldPosition: position, newPosition: CLLocationCoordinate2D(latitude: markerInfo.latitude, longitude: markerInfo.longtitude), heading: markerInfo.heading, driverName: markerInfo.driverName, vehicleNo: markerInfo.vehicleNo, mapView: mapView)
                    }
                    else{
                        setMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo, markerInfo.vehicleID), mapView: mapView)
                        setPulseMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo), mapView: mapView)
                    }
                }
                else{
                    setMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo, markerInfo.vehicleID), mapView: mapView)
                    setPulseMarker(info: (markerInfo.latitude, markerInfo.longtitude, markerInfo.heading, markerInfo.driverName, markerInfo.vehicleNo), mapView: mapView)
                }
                positions[markerInfo.vehicleID] = CLLocationCoordinate2D(latitude: markerInfo.latitude, longitude: markerInfo.longtitude)
            }
        }
        self.view.bringSubview(toFront: menu)
        self.view.bringSubview(toFront: camera)
    }
    
    func animateMoveMarker(oldPosition: CLLocationCoordinate2D, newPosition: CLLocationCoordinate2D, heading: Int, driverName: String, vehicleNo: String, vehicleID: String, mapView: GMSMapView){
        let marker = GMSMarker()
        marker.icon = self.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 35, height: 17))
        marker.title = driverName
        marker.snippet = vehicleNo
        marker.userData = vehicleID
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.rotation = CLLocationDegrees(getHeadingForDirection(fromCoordinate: oldPosition, toCoordinate: newPosition))
        //found bearing value by calculation when marker add
        marker.position = oldPosition
        //this can be old position to make car movement to new position
        marker.map = mapView
        //marker movement animation

        CATransaction.begin()
        CATransaction.setValue(Int(60.0), forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({() -> Void in
            marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            marker.rotation = CDouble(heading+90)
            //New bearing value from backend after car movement is done
            marker.map = nil
        })
        marker.position = newPosition
        //this can be new position after car moved from old position to new position with animation
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.rotation = CDouble(getHeadingForDirection(fromCoordinate: oldPosition, toCoordinate: newPosition))
        //found bearing value by calculation
        CATransaction.commit()
        print("animateMovemarker")
    }
    
    func animateMovePulseMarker(oldPosition: CLLocationCoordinate2D, newPosition: CLLocationCoordinate2D, heading: Int, driverName: String, vehicleNo: String, mapView: GMSMapView){
        let marker = GMSMarker()
        marker.iconView = circle
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.position = oldPosition
        //this can be old position to make car movement to new position
        marker.map = mapView
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        opacityAnimation.duration = 2
        scaleAnimation.duration = 2
        opacityAnimation.repeatCount = Float.infinity
        scaleAnimation.repeatCount = Float.infinity
        //scaleAnimation.autoreverses = true
        opacityAnimation.fromValue = 0.8
        scaleAnimation.fromValue = 0.4
        opacityAnimation.toValue = 0.1
        scaleAnimation.toValue = 1
        
        circle.layer.add(scaleAnimation, forKey: "scale")
        circle.layer.add(opacityAnimation, forKey: "nil")
        CATransaction.begin()
        CATransaction.setValue(Int(60.0), forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({() -> Void in
            marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            //New bearing value from backend after car movement is done
            marker.map = nil
        })
        marker.position = newPosition
        //this can be new position after car moved from old position to new position with animation
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        CATransaction.commit()
        print("animatepulesemarker")
    }

    
    func getHeadingForDirection(fromCoordinate fromLoc: CLLocationCoordinate2D, toCoordinate toLoc: CLLocationCoordinate2D) -> Float {
        
        let fLat: Float = Float((fromLoc.latitude).degreesToRadians)
        let fLng: Float = Float((fromLoc.longitude).degreesToRadians)
        let tLat: Float = Float((toLoc.latitude).degreesToRadians)
        let tLng: Float = Float((toLoc.longitude).degreesToRadians)
        let degree: Float = (atan2(sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))).radiansToDegrees
        if degree >= 0 {
            return degree+90
        }
        else {
            return 360 + degree+90
        }
    }
    
    func setMarker(info: (latitude: Double, longitude: Double, heading: Int, driverName: String, vehicleNo: String, vehicleID: String), mapView: GMSMapView){
        let marker = GMSMarker()
        marker.icon = self.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 35, height: 17))
        marker.position = CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude)
        marker.rotation = CDouble(info.heading+90)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.title = info.driverName
        marker.snippet = info.vehicleNo
        marker.userData = info.vehicleID
        marker.map = mapView
        let when = DispatchTime.now() + 60 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            marker.map = nil
        }
        print("setMarker!")
    }
    
    func setPulseMarker(info: (latitude: Double, longitude: Double, heading: Int, driverName: String, vehicleNo: String), mapView: GMSMapView){
        let marker = GMSMarker()
        marker.iconView = circle
        marker.position = CLLocationCoordinate2D(latitude: info.latitude, longitude: info.longitude)
        marker.map = mapView
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        opacityAnimation.duration = 2
        scaleAnimation.duration = 2
        opacityAnimation.repeatCount = Float.infinity
        scaleAnimation.repeatCount = Float.infinity
        //scaleAnimation.autoreverses = true
        opacityAnimation.fromValue = 0.8
        scaleAnimation.fromValue = 0.4
        opacityAnimation.toValue = 0.1
        scaleAnimation.toValue = 1
        
        circle.layer.add(scaleAnimation, forKey: "scale")
        circle.layer.add(opacityAnimation, forKey: "nil")
        let when = DispatchTime.now() + 60 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            marker.map = nil
        }
        print("setPulseMarker!")
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: newSize.width, height: newSize.height))  )
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func writeTracklistRequest(date: Int){
        socket.write(string: "{\"cmd\": \"REQ_TRACKLIST\", \"sts\": 0, \"grp\": \"All\", \"dat\": \(date)}")
    }
    
    func writeVehicleEventRequest(vehicleId: String, date: Int) {
        socket.write(string: "{\"cmd\": \"REQ_VEHICLEEVENT\", \"vid\": \"\(vehicleId)\", \"dat\": \(date)}")
    }
    
    public func writeVehicleTrackRequest(vehicleId: String, date: Int) {
        socket.write(string: "{\"cmd\": \"REQ_VEHICLETRACK\", \"vid\": \"\(vehicleId)\", \"dat\": \(date)}")
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
        writeTracklistRequest(date: todayDate())
    }
    
    func todayDate() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let year =  components.year
        let month = components.month
        let day = components.day
        return year!*10000+month!*100+day!
    }
    
    func todayTime() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        return hour*10000+minutes*100+seconds
    }
    
    func todayYear() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year
    }
    
    func todayMonth() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        return month
    }
    
    func todayDay() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return day
    }
    
    
    func videoPlay(url: String){
        let videoURL = URL(string: url)
        let player = AVPlayer(url: videoURL!)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        let track = AVAsset(url: videoURL!).tracks(withMediaType: AVMediaTypeVideo).first
        let videoSize = (track?.naturalSize)!.applying((track?.preferredTransform)!)
        playerController.view.frame = CGRect(x: 0, y: view.frame.height - view.frame.width*videoSize.height/videoSize.width, width: view.frame.width, height: view.frame.width*videoSize.height/videoSize.width)
        self.view.addSubview(playerController.view)
        self.view.bringSubview(toFront: playerController.view)
        self.addChildViewController(playerController)
        
        player.play()
        
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        } else {
            print("websocket disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Received text: \(text)")
        if let convertedText = vc.convertToDictionary(text: text){
            if let cmd = convertedText["cmd"] as? String {
                if cmd == "RPS_TRACKLIST"{
                    if isFirstTracklistRPS{
                        if let vehicleValues = convertedText["values"] as? [[String: Any]] {
                            var sumLatitude = 0.0, sumLongtitude = 0.0, count = 0.0
                            var markersInfo = [(Double, Double, Int, String, String, Int, String, String)]()
                            var vehiclesInfo = [(String, String, String, (Double, Double), Int, Int, Int, Int)]()
                            for value in vehicleValues {
                                let vehicle = Vehicle(json: value)
                                print(vehicle?.location ?? "Failed to initialize drivers")
                                vehiclesInfo.append(((vehicle?.driverName)!,(vehicle?.vehicleNo)!,(vehicle?.vehicleID)!,(vehicle?.location)!, (vehicle?.heading)!, (vehicle?.time)!, (vehicle?.eventsNo)!, (vehicle?.distance)!))
                                if (vehicle?.location.latitude != 0) && (vehicle?.location.longitude != 0){
                                    sumLatitude += (vehicle?.location.latitude)!
                                    sumLongtitude += (vehicle?.location.longitude)!
                                    count += 1
                                    markersInfo.append(((vehicle?.location.latitude)!, (vehicle?.location.longitude)!, (vehicle?.heading)!, (vehicle?.driverName)!, (vehicle?.vehicleNo)!, (vehicle?.status)!, (vehicle?.deviceNo)!, (vehicle?.vehicleID)!))
                                }
                            }
                            let avgLatitude = sumLatitude/count
                            let avgLongtitude = sumLongtitude/count
                            initiateMapView(cameraLocation: (avgLatitude, avgLongtitude), markersInfo: markersInfo)
                            initializeVehicleArray(vehiclesInfo: vehiclesInfo)
                            isFirstTracklistRPS = false
                        }
                    }
                    else{
                        if let vehicleValues = convertedText["values"] as? [[String: Any]] {
                            var count = 0.0
                            var markersInfo = [(Double, Double, Int, String, String, Int, String, String)]()
                            for value in vehicleValues {
                                let vehicle = Vehicle(json: value)
                                print(vehicle?.location ?? "Failed to initialize drivers")
                                if (vehicle?.location.latitude != 0) && (vehicle?.location.longitude != 0){
                                    count += 1
                                    markersInfo.append(((vehicle?.location.latitude)!, (vehicle?.location.longitude)!, (vehicle?.heading)!, (vehicle?.driverName)!, (vehicle?.vehicleNo)!, (vehicle?.status)!, (vehicle?.deviceNo)!, (vehicle?.vehicleID)!))
                                    updateVehicleArray(vehicleId: (vehicle?.vehicleID)!, time: (vehicle?.time)!, eventsNo: (vehicle?.eventsNo)!, distance: (vehicle?.distance)!)
                                }
                            }
                            updateMapView(markersInfo: markersInfo)
                        }
                    }
                }
                if cmd == "RPS_MDT"{
                    videoPlay(url: "http://120.146.195.80:100/VEHICLE/00001/2017/07/28/MP4/20170728_131530_ch1_5.MP4")
                    if let ifSuccessful = convertedText["res"] as? String {
                        if ifSuccessful == "OK"{
                            let url: String = "\(mainUrl)/VEHICLE/\(selectedVehicleId)/\(todayYear())/\(todayMonth())/\(todayDay())/MP4/\(todayDate())_\(selectedTime)_ch1_5.MP4"
                            videoPlay(url: url)
                        }
                    }
                }
                if cmd == "RPS_VEHICLETRACK"{
                    if let eda2 = convertedText["eda2"] as? [String: Any]{
                        if let scoDict = eda2["sco"] as? [Any]{
                            selectedScore = scoDict[4] as! Int
                        }
                    }
                    else{
                        selectedScore = 0
                    }
                    if let tracks = convertedText["values"] as? [[String: Any]]{
                        var Positions = [Int: (CLLocationCoordinate2D, Int)]()
                        for track in tracks {
                            let trkDetail = Track(json: track)
                            if trkDetail?.location.latitude != 0 {
                                Positions[(trkDetail?.time)!] = (CLLocationCoordinate2D(latitude: (trkDetail?.location.latitude)!, longitude: (trkDetail?.location.longitude)!), (trkDetail?.heading)!)
                            }
                        }
                        trackPositions = Positions
                    }
                    else{
                        trackPositions.removeAll()
                    }
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateScoreNotification"), object: nil)
                }
                if cmd == "RPS_VEHICLEEVENT"{
                    if let eventValues = convertedText["values"] as? [[String: Any]] {
                        var Events = [Int: (CLLocationCoordinate2D, String)]()
                        for value in eventValues{
                            let event = Event(json: value)
                            if event?.location.latitude != 0 {
                                Events[(event?.time)!] = (CLLocationCoordinate2D(latitude: (event?.location.latitude)!, longitude: (event?.location.longitude)!), (event?.type)!)
                            }
                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateEventNotification"), object: Events)
                    }
                }
                if isTrackingHistory{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateCompoundNotification"), object: nil)
                }
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received data: \(data.count)")
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}

extension MapViewController : SlideMenuControllerDelegate {
    
    func leftWillOpen() {
        print("SlideMenuControllerDelegate: leftWillOpen")
    }
    
    func leftDidOpen() {
        print("SlideMenuControllerDelegate: leftDidOpen")
    }
    
    func leftWillClose() {
        print("SlideMenuControllerDelegate: leftWillClose")
    }
    
    func leftDidClose() {
        print("SlideMenuControllerDelegate: leftDidClose")
    }
    
    func rightWillOpen() {
        print("SlideMenuControllerDelegate: rightWillOpen")
    }
    
    func rightDidOpen() {
        print("SlideMenuControllerDelegate: rightDidOpen")
    }
    
    func rightWillClose() {
        print("SlideMenuControllerDelegate: rightWillClose")
    }
    
    func rightDidClose() {
        print("SlideMenuControllerDelegate: rightDidClose")
    }
}
