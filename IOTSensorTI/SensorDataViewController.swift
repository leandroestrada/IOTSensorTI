//
//  SensorDataViewController.swift
//  IOTSensorTI
//
//  Created by leandro de araujo estrada on 14/06/20.
//  Copyright © 2020 leandro de araujo estrada. All rights reserved.
//


import UIKit
import AVFoundation
import Foundation

class SensorDataViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var luzLbl: UILabel!
    @IBOutlet weak var lblHum: UILabel!
    @IBOutlet weak var tmpLbl: UILabel!
    @IBOutlet weak var giroLblY: UILabel!
    @IBOutlet weak var giroLblX: UILabel!
    @IBOutlet weak var giroLblZ: UILabel!
    @IBOutlet weak var aceleLblY: UILabel!
    @IBOutlet weak var aceleLblX: UILabel!
    @IBOutlet weak var aceleLblZ: UILabel!
    @IBOutlet weak var magnetLblY: UILabel!
    @IBOutlet weak var magnetLblX: UILabel!
    @IBOutlet weak var magnetLblZ: UILabel!
    @IBOutlet weak var luzImg: UIImageView!
    @IBOutlet weak var umidImg: UIImageView!
    @IBOutlet weak var tempImg: UIImageView!
    
    // MARK: - Variables
    
    let systemSoundIDVibrate: SystemSoundID = 4095
    var trainHorn: AVAudioPlayer = AVAudioPlayer()
    var currentPeriod: UInt8 = 0
    var luz: Double = 0
    var luzString = ""
    var hum: Double = 0
    var lastMessage: CFAbsoluteTime = 0
    var humTemp: [Double] = []
    var second: [Double] = []
    var umidVal: Double = 0
    var umidValC: Int = 0
    var tempVal: Double = 0
    var tempValC: Int = 0
    var timePicker = UIPickerView()
    var time : [String] = ["1.0","2.0","3.0","4.0","5.0"]
    var pickerSelecionado: Double = 0.5
    var sensorPicker = UIPickerView()
    var sensores : [String] = ["sensor1", "sensor2", "sensor3"]
    
    private var phoneNumber: String = ""
    private var sensorId: String = ""
    private var lumosMinimumValue: Int = 10000
    private var lumosMaxValue: Int = 10000
    private var timeScan: Int = 1
    
    private var timerToUpdateUI = Timer()
    
    private var seconds = 0
    private var isValidTimer = false
    private var timer = Timer()
    private var each15 = Timer()
    private var lastLuminosidade : Int?
    private var isValidToSendPostM1 = false
    private var isValidToSendPostM3 = false
    private var isValidToSendPostM2 = false
    private var isValidToSendPostM4 = false
    
    private var iotSecondsM3 = 0
    private var isValidTimerIotM3 = false
    private var iotSecondsM1 = 0
    private var isValidTimerIotM1 = false
    
    var p1 = false
    var p2 = false
    var p3 = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trainHornURL = Bundle.main.path(forResource: "TRAIN Sound Effects - Steam Train Start and Whistle", ofType: ".mp3")
        
        do {
            try trainHorn = AVAudioPlayer(contentsOf: URL (fileURLWithPath: trainHornURL!))
        } catch {
        
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
//        timerToUpdateUI = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateUI), userInfo: nil, repeats: true)
//
//        let timer2 = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimerIot), userInfo: nil, repeats: true)
//
//        if let userInputsVC = tabBarController?.viewControllers![1] as? UserInputsViewController {
//            self.phoneNumber = userInputsVC.numberToSend
//            if userInputsVC.sensorID != nil {
//                self.sensorId = userInputsVC.sensorID.text!
//            }
//            if userInputsVC.luxometerSensor != nil && userInputsVC.timeScanSensor != nil {
//                self.lumosMinimumValue = Int(userInputsVC.luxometerSensor.value * 500)
//                self.lumosMaxValue = Int(userInputsVC.luxometerSensorMax.value * 5000)
//                self.timeScan = Int(userInputsVC.timeScanSensor.value * 10)
//            }
//        }
    }
    
    @objc func updateUI() {
        
        let peripheralData = Peripherals.shared
        luzLbl.text = peripheralData.luzString
        lblHum.text = peripheralData.humString
        tmpLbl.text = peripheralData.tempString
        tempImg.image = UIImage.init(named: peripheralData.temperatureImageString)
        giroLblX.text = peripheralData.giroStringX
        giroLblY.text = peripheralData.giroStringY
        giroLblZ.text = peripheralData.giroStringZ
        aceleLblX.text = peripheralData.aceleStringX
        aceleLblY.text = peripheralData.aceleStringY
        aceleLblZ.text = peripheralData.aceleStringZ
        magnetLblX.text = peripheralData.magnetStringX
        magnetLblY.text = peripheralData.magnetStringY
        magnetLblZ.text = peripheralData.magnetStringZ
        
        if let luminosidade = Int(luzLbl.text!) {
            Requests.shared.luzString = String(luminosidade)
            sendPostIot(luminosidade: luminosidade)
            sendPostOData(luminosidade: luminosidade)
        }

    }
    
    /* enviar post iot*/
    func sendPostIot(luminosidade: Int) {
        
        let post = Requests.shared
        
        if isValidTimerIotM1 {
            isValidTimerIotM1 = false
            isValidTimerIotM3 = false
            iotSecondsM3 = 0
            post.postIot(typeM: 1)
        } else if luminosidade < lumosMinimumValue {
            post.postIot(typeM: 2)
            p2 = true
            if iotSecondsM3 == 0 {
                isValidTimerIotM3 = true
            } else if iotSecondsM3 >= 20 {
                post.postIot(typeM: 3)
            }
        } else if luminosidade > lumosMaxValue {
            isValidTimerIotM3 = false
            iotSecondsM3 = 0
            post.postIot(typeM: 4)
            p1 = true
        } else {
            isValidTimerIotM3 = false
            iotSecondsM3 = 0
            post.postIot(typeM: 0)
        }
    }
    
    /* enviar post oData */
    func sendPostOData(luminosidade: Int) {
        
        let post = Requests.shared
        let temporaryPhone = self.phoneNumber
        
        if luminosidade >= 5000 {
            post.postIot(typeM: 99)
            p3 = true
        }
        
        if (p1 == true || p2 == true) && p3 == true {
            post.postIot(typeM: 100)
            p1 = false
            p2 = false
            p3 = false
        }
        
        if luminosidade < lumosMinimumValue {
            
            if isValidToSendPostM2 {
                isValidToSendPostM2 = false
                post.postOData(typeM: 2)
            }
            
            if isValidToSendPostM3 {
                if seconds == 0 {
                    isValidTimer = true
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
                } else if seconds >= 10 {
                    isValidTimer = false
                    seconds = 0
                    post.postOData(typeM: 3)
                    //posta M3
                    isValidToSendPostM3 = false
                }
            }
            
            // Envia POST SMS
            if temporaryPhone != "" {
                let temporaryPhone = self.phoneNumber
                post.requestForSms(id: self.sensorId, luxometer: Double(luminosidade), limit: Double(self.lumosMinimumValue), date: "", phoneNumber: temporaryPhone)
                self.phoneNumber = ""
            }
        } else if luminosidade >= lumosMinimumValue && luminosidade <= lumosMaxValue {
            isValidToSendPostM3 = true
            isValidToSendPostM2 = true
            isValidToSendPostM1 = true
        } else if luminosidade > lumosMaxValue {
            isValidToSendPostM3 = true
            if isValidToSendPostM2 {
                isValidToSendPostM2 = false
                post.postOData(typeM: 2)
            }
        }
    }
    
    @objc func updateTimer() {
        if isValidTimer == true {
            seconds += 1
        }
    }
    
    @objc func updateTimerIot(){
        if isValidTimerIotM3 {
            iotSecondsM3 += 1
        }
        iotSecondsM1 += 1
        if iotSecondsM1 >= 900*2 {
            iotSecondsM1 = 0
            isValidTimerIotM1 = true
        }
    }
}
