# DMS5
An IOS 10.0 mobile application for online vehicle tracking system of Truck Rear Vison Systems.

Written in Swift 3.0 with CocoaPods dependencies of Alamofire, SwiftJSON, Starscream, GoogleMpas. To run the project, you need to install the pod file first. For pod install, see more info on https://cocoapods.org.

The project is based on the websocket communication between the app and our DMS server-side program. <span style="color:red">**As the server process runs on port 100, make sure your network or firewall settings will not block this port connection**.</span>

The project involves google API key to locate vehicles and call navigation services by Rest. There's upper limit per day so do not overuse for business purpose, see more info on https://developers.google.com/maps/faq. 

The video demo of this app: https://www.youtube.com/watch?v=Bxm77tIw05U.

To run this app, just clone or download the repository to your local path and open DMS5.xcworkspace in XCode after intalling pods. 
