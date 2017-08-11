# DMS5
An IOS 10.0 mobile application for online vehicle tracking system of Truck Rear Vison Systems.

Written in Swift 3.0 with CocoaPods dependencies of Alamofire, SwiftJSON, Starscream, GoogleMpas. To run the project, you need to install the pod file first. For pod install, see more info on https://cocoapods.org.

The project is based on the websocket communication between the app and our DMS server-side program. <span style="color:red">**As the server process runs on port 100, make sure your network or firewall settings will not block this port connection**.</span>

The project involves google API key to locate vehicles and call navigation services by Rest. There's upper limit per day so do not overuse for business purpose, see more info on https://developers.google.com/maps/faq. 

The video demo of this app will be uploaded afterwards.

To run this app, just clone or download the repository to your local path and open DMS5.xcworkspace in XCode after intalling pods. 

<img src="https://user-images.githubusercontent.com/28894500/29198451-6e037a3e-7e87-11e7-8a2f-e1f8707e45fc.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198462-7b743636-7e87-11e7-96ba-805d9a3d359b.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198466-812eb72c-7e87-11e7-8f94-91cdf5f916c4.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198473-8b50bec6-7e87-11e7-9e8a-0f8733edb8c1.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198476-8f30227a-7e87-11e7-9932-7ecf4e4a0ea9.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198478-9270facc-7e87-11e7-8911-6916223a4186.jpeg" width="200">   <img src="https://user-images.githubusercontent.com/28894500/29198573-ac51d212-7e88-11e7-84ae-2d312e30c851.jpeg" width="200">
