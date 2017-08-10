//
//  ViewController.swift
//  DMS5
//
//  Created by 黄 康平 on 5/3/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import UIKit
import Starscream



class ViewController: UIViewController, WebSocketDelegate {
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var logintext: UILabel!
    @IBOutlet weak var userview: UIView!
    @IBOutlet weak var passwordview: UIView!
    @IBOutlet weak var userlogo: UIImageView!
    @IBOutlet weak var passwordlogo: UIImageView!
    @IBOutlet weak var userinput: UITextField!
    @IBOutlet weak var passwordinput: UITextField!
    @IBOutlet weak var submit: UIButton!
    
    @IBAction func submit(_ sender: UIButton) {
        if let uid = userinput.text , let pwd = passwordinput.text{
            if (uid != "") && (pwd != ""){
                socket.write(string: "{\"cmd\": \"REQ_LOGIN\", \"uid\": \"\(uid)\", \"pwd\": \"\(pwd)\"}")
            }
        }
    }
    
    var socket = WebSocket(url: URL(string:"ws://120.146.195.80:100/ws")!)

    override func viewDidLoad() {
        super.viewDidLoad()
        logo.frame = CGRect(x: 0.15*view.frame.width, y: 0.15*view.frame.height, width: 0.7*view.frame.width, height: 0.18*view.frame.height)
        logintext.frame = CGRect(x: 0.15*view.frame.width, y: 0.35*view.frame.height, width: 0.7*view.frame.width, height: 0.1*view.frame.height)
        userview.frame = CGRect(x: 0.15*view.frame.width, y: 0.43*view.frame.height, width: 0.7*view.frame.width, height: 50)
        userview.layer.cornerRadius = 10
        passwordview.layer.cornerRadius = 10
        submit.layer.cornerRadius = 10
        passwordview.frame = CGRect(x: 0.15*view.frame.width, y: 0.43*view.frame.height+58, width: 0.7*view.frame.width, height: 50)
        submit.frame = CGRect(x: 0.15*view.frame.width, y: 0.43*view.frame.height+118, width: 0.7*view.frame.width, height: 50)
        socket.delegate = self
        socket.connect()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
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
        let convertedText = convertToDictionary(text: text)
        if let cmd = convertedText!["cmd"] as? String {
            if cmd == "RPS_LOGIN"{
                if let res = convertedText!["res"] as? Int {
                    if res == 0 {
                        socket.disconnect()
                        let next = self.storyboard?.instantiateViewController(withIdentifier: "container") as! ContainerViewController
                        self.present(next, animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Received data: \(data.count)")
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

