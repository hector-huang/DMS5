//
//  Vehicle.swift
//  DMS5
//
//  Created by 黄 康平 on 5/29/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import Foundation

public struct Vehicle {
    
    public let driverName: String
    public let vehicleNo: String
    public let heading: Int
    public let location: (latitude: Double, longitude: Double)
    public let status: Int
    public let deviceNo: String
    public let vehicleID: String
    public let time: Int
    public let eventsNo: Int
    public let distance: Int
    
    public init?(json: [String: Any]) {
        guard let driverName = json["dno"] as? String,
            let vehicleNo = json["vno"] as? String,
            let heading = json["ghd"] as? Int,
            let latitude = json["lat"] as? Double,
            let longitude = json["lon"] as? Double,
            let status = json["atv"] as? Int,
            let deviceNo = json["dei"] as? String,
            let vehicleID = json["vid"] as? String,
            let time = json["tim"] as? Int,
            let eventsNo = json["evt"] as? Int,
            let distance = json["edt"] as? Int
        else {
            return nil
        }
        self.driverName = driverName
        self.vehicleNo = vehicleNo
        self.heading = heading
        self.location = (latitude, longitude)
        self.status = status
        self.deviceNo = deviceNo
        self.vehicleID = vehicleID
        self.time = time
        self.eventsNo = eventsNo
        self.distance = distance
    }
}
