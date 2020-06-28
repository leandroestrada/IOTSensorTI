import UIKit
import CoreBluetooth
import Foundation
import WatchConnectivity
import AVFoundation


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate/* WCSessionDelegate*/ {
    
    // MARK - Outlets
    
    
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
    var pickerSelecionado: Double = 1.0
    var sensorPicker = UIPickerView()
    var sensores : [String] = ["sensor1", "sensor2", "sensor3"]
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    
    
    // MARK: - Variables Sensor
    
    let svcHumidity = CBUUID.init(string: "F000AA20-0451-4000-B000-000000000000")
    let svcTemperature = CBUUID.init(string: "F000AA00-0451-4000-B000-000000000000")
    let svcLight = CBUUID.init(string: "F000AA70-0451-4000-B000-000000000000")
    let svcAccelerometer = CBUUID.init(string: "F000AA10-0451-4000-B000-000000000000")
    let svcBarometer = CBUUID.init(string: "F000AA40-0451-4000-B000-000000000000")
    let svcMovement = CBUUID.init(string: "F000AA80-0451-4000-B000-000000000000")
    let svcMagnetometer = CBUUID.init(string: "F000AA30-0451-4000-B000-000000000000")
    let temperData = CBUUID.init(string: "F000AA01-0451-4000-B000-000000000000")
    let temperConfig = CBUUID.init(string: "F000AA02-0451-4000-B000-000000000000")
    let accelerometerData = CBUUID.init(string: "F000AA11-0451-4000-B000-000000000000")
    let accelerometerConfig = CBUUID.init(string: "F000AA12-0451-4000-B000-000000000000")
    let magnetometerData = CBUUID.init(string: "F000AA31-0451-4000-B000-000000000000")
    let magnetometerConfig = CBUUID.init(string: "F000AA32-0451-4000-B000-000000000000")
    let barometerData = CBUUID.init(string: "F000AA41-0451-4000-B000-000000000000")
    let barometerConfig = CBUUID.init(string: "F000AA42-0451-4000-B000-000000000000")
    let movementData = CBUUID.init(string: "F000AA81-0451-4000-B000-000000000000")
    let movementConfig = CBUUID.init(string: "F000AA82-0451-4000-B000-000000000000")
    let movementPeriod = CBUUID.init(string: "F000AA83-0451-4000-B000-000000000000")
    let charHumidityData = CBUUID.init(string: "F000AA21-0451-4000-B000-000000000000" )
    let charHumidityConfig = CBUUID.init(string: "F000AA22-0451-4000-B000-000000000000")
    let charLightConfig = CBUUID.init(string: "F000AA72-0451-4000-B000-000000000000")
    let charLightData = CBUUID.init(string: "F000AA71-0451-4000-B000-000000000000")
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        timePicker.delegate = self  //PICKER INTERVALO
        timePicker.dataSource = self //PICKER INTERVALO
        //timeTextField.inputView = timePicker; formatter.formatOptions.insert(.withFractionalSeconds) //PICKER INTERVALO
        
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        let trainHornURL = Bundle.main.path(forResource: "TRAIN Sound Effects - Steam Train Start and Whistle", ofType: ".mp3")
        do {
            try trainHorn = AVAudioPlayer(contentsOf: URL (fileURLWithPath: trainHornURL!))
        }
        catch{
            print(error)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            print ("scanning...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains("SensorTag") == true {
            print (peripheral.name ?? "no name")
            centralManager.stopScan()
            print (advertisementData)
            central.connect(peripheral, options: nil)
            myPeripheral = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("connected \(peripheral.name)")
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for svc in services {
                if svc.uuid == svcLight {
                    print (svc.uuid.uuidString)
                    peripheral.discoverCharacteristics(nil, for: svc)
                }
                if svc.uuid == svcHumidity{
                    print(svc.uuid.uuidString)
                    peripheral.discoverCharacteristics(nil, for: svc)
                }
                if svc.uuid == svcBarometer{
                    print(svc.uuid.uuidString)
                    peripheral.discoverCharacteristics(nil, for: svc)
                }
                if svc.uuid == svcMovement{
                    print(svc.uuid.uuidString)
                    peripheral.discoverCharacteristics(nil, for: svc)
                }
                if svc.uuid == svcTemperature{
                    print(svc.uuid.uuidString)
                    peripheral.discoverCharacteristics(nil, for: svc)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let chars = service.characteristics {
            for char in chars {
                print (char.uuid.uuidString)
                if char.uuid == charHumidityConfig {
                    if char.properties.contains(CBCharacteristicProperties.writeWithoutResponse){
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withoutResponse)
                    } else {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withResponse)
                    }
                }
                else if char.uuid == charHumidityData{
                    checkHumidity(curChar: char)
                }
                    
                    //TEMPERATURA
                else if char.uuid == temperConfig {
                    if char.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withoutResponse)
                    } else {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withResponse)
                    }
                }
                    //GIROSCOPIO
                else if char.uuid == movementConfig{
                    
                    // FF - with WOM
                    // 7F - all sensors on, 03 - 16 G
                    let bytes : [UInt8] = [ 0x7F, 0x03 ]
                    let data = Data(bytes:bytes)
                    
                    peripheral.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if char.uuid == movementPeriod {
                    print ("Changing period")
                    let bytes : [UInt8] = [ currentPeriod ]
                    let data = Data(bytes:bytes)
                    peripheral.writeValue(data, for: char, type: CBCharacteristicWriteType.withResponse)
                }
                else if char.uuid == movementData{
                    checkMovement(curChar: char)
                }
                    //BAROMETRO
                else if char.uuid == barometerData{
                    if char.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withoutResponse)
                    } else {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withResponse)
                    }
                }
                    //LUZ
                else if char.uuid == charLightConfig {
                    if char.properties.contains(CBCharacteristicProperties.writeWithoutResponse) {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withoutResponse)
                    } else {
                        peripheral.writeValue(Data.init(bytes: [01]), for: char, type: CBCharacteristicWriteType.withResponse)
                    }
                }
                else if char.uuid == charLightData {
                    checkLight(curChar: char)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print ("wrote value")
    }
    
    func dataToUnsignedBytes16(value : Data) -> [UInt16] {
        let count = value.count
        var array = [UInt16](repeating: 0, count: count)
        (value as NSData).getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }
    
    func dataToSignedBytes16(value : NSData) -> [Int16] {
        let count = value.length
        var array = [Int16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int16>.size)
        return array
    }
    
    func dataToUnsignedBytes16(value : NSData) -> [UInt16] {
        let count = value.length
        var array = [UInt16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }
    
    func dataToSignedBytes8(value : NSData) -> [Int8] {
        let count = value.length
        var array = [Int8](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int8>.size)
        return array
    }
    
    
    //******************** POST *********************
    
    func ISOStringFromDate(date: Date) -> String {
        let timezone = "UTC"
        let locale = "en_US_POSIX"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: locale) as Locale!
        dateFormatter.timeZone = NSTimeZone(abbreviation: timezone) as! TimeZone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: date as Date)
    }
    
    
    var sessao = URLSession(configuration: .default)
    var baseURL = URL(string: "https://iotmmss0009452156trial.hanatrial.ondemand.com/com.sap.iotservices.mms/v1/api/http/data/ceb113b9-a0f0-43b7-849e-af98797fc344")
    let date = Date()
    let formatter = ISO8601DateFormatter()
    var luminosidade: Double = 0.0
    
    
    
    
    @IBAction func postando(_ sender: UIButton)  {
        //sender.pulsate()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        var mode: String = "sync"
        var messageType: String = "eda3550e5d06b2210acd"
        
        var timestamp: String = "2018-08-14T18:43:15.799Z"
        var temperature: Double? = tempVal1
        
        var humidity: Double? = umidVal
        
        var pressure: Double = 0.0
        
        var gyro_x: Double? = dadosGiroX
        var gyro_y: Double? = dadosGiroY
        var gyro_z: Double? = dadosGiroZ
        
        var battery_level: Double = 0
        var system_id: String = "54:6c:0e:00:00:53:02:cc"
        
        var magnetometer_x: Double = xMagVal
        var magnetometer_y: Double = yMagVal
        var magnetometer_z: Double = zMagVal
        
        var accelerometer_x1: Double = accXDouble
        var accelerometer_y1: Double = accYDouble
        var accelerometer_z1: Double = accZDouble
        
        var serial_number: String = "N.A."
        var distance: Double = 0.0
        var lightness: Double = luminosidade
        var device_name: String = "CC2650 SensorTag"
        
        let mensagem : [[String : Any ]] = [[
            "timestamp" : timestamp,
            "temperature" : temperature,
            "humidity" : humidity,
            "pressure" : 0,
            "giro_x" : gyro_x,
            "giro_y" : gyro_y,
            "giro_z" : gyro_z,
            "battery_level" : 0,
            "system_id" : "54:6c:0e:00:00:53:02:cc",
            "magnetometer_x" : magnetometer_x,
            "magnetometer_y" : magnetometer_y,
            "magnetometer_z" : magnetometer_z,
            "accelerometer_x" : accelerometer_x1,
            "accelerometer_y" : accelerometer_y1,
            "accelerometer_z" : accelerometer_z1,
            "serial_number" : "N.A.",
            "distance" : 0,
            "lightness" : luminosidade,
            "device_name" : "CC2650 SensorTag"
            ]]
        
        let dadosIOT : [String : Any] = ["mode" : "sync", "messageType" : "eda3550e5d06b2210acd", "messages" : mensagem]
        
        guard let url = URL(string: "https://iotmmss0009452156trial.hanatrial.ondemand.com/com.sap.iotservices.mms/v1/api/http/data/ceb113b9-a0f0-43b7-849e-af98797fc344") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer 3da6d1d4a6247b39f5a151353083117a", forHTTPHeaderField: "Authorization")
        request.addValue("charset=utf-8", forHTTPHeaderField: "Accept-Charset")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: dadosIOT, options: []) else { return }
        
        request.httpBody = httpBody
        
        let session = URLSession.shared
        
        session.dataTask(with: request) { (data, response, error) in
            
            if error == nil {
                
                guard let umaResposta = response as? HTTPURLResponse else {return}
                
                if umaResposta.statusCode == 200 {
                    DispatchQueue.main.async {
                        msgCadastradoComSucesso()
                    }
                } else {
                    DispatchQueue.main.async {
                        msgErro()
                    }
                }
            }
            }.resume()
        
        // Mensagens
        func msgCadastradoComSucesso () {
            let alerta = UIAlertController(title: "Alerta", message: "Cadastro efetuado com sucesso.", preferredStyle: .alert)
            let acaoOk = UIAlertAction(title: "OK", style: .default, handler: nil)
            alerta.addAction(acaoOk)
            self.present(alerta, animated: true, completion: nil)
        }
        
        func msgErro() {
            let alerta = UIAlertController(title: "Alerta", message: "Erro ao gravar o cadastro, tente novamente", preferredStyle: .alert)
            let acaoOk = UIAlertAction(title: "OK", style: .default, handler: nil)
            alerta.addAction(acaoOk)
            self.present(alerta, animated: true, completion: nil)
        }
    }
    
    
    //**********************UMIDADE**************************
    var tempVal1: Double = 0
    var humVal1: Double = 0
    
    func getRelativeHumidity(value: NSData) -> [Double] {
        let dataFromSensor = dataToUnsignedBytes16(value: value)
        let humidity = Double(-6 + 125/65536 * Double(dataFromSensor[1]))
        let temperature = Double(-40 + ((165  * Double(dataFromSensor[0])) / 65536.0))
        
        humTemp = [humidity, temperature]
        umidVal = humTemp[0]
        if umidVal < 100.00{
            umidValC = Int(humTemp[0])
        }
        //Para evitar o -40
        tempVal = humTemp[1]
        if tempVal > 0{
            tempVal1 = tempVal
        }
        tempValC = Int(humTemp[1])
        
        return humTemp
        
    }
    
    //********************MAGNETOMETRO************************
    
    var xMagVal: Double = 0
    var yMagVal: Double = 0
    var zMagVal: Double = 0
    
    func getMagnetometerData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let xVal = Double(dataFromSensor[0]) * 2000 / 65536 * -1
        let yVal = Double(dataFromSensor[1]) * 2000 / 65536 * -1
        let zVal = Double(dataFromSensor[2]) * 2000 / 65536
        
        return [xVal, yVal, zVal]
    }
    
    //**********************LUZ********************************
    func luxConvert(value : Data) -> Double {
        let rawData = dataToUnsignedBytes16(value: value)
        var e :UInt16 = 0
        var m :UInt16 = 0
        
        m = rawData[0] & 0x0FFF;
        e = (rawData[0] & 0xF000) >> 12;
        
        /** e on 4 bits stored in a 16 bit unsigned => it can store 2 << (e - 1) with e < 16 */
        e = (e == 0) ? 1 : 2 << (e - 1);
        
        return Double(m) * (0.01 * Double(e));
    }
    
    //********************* GIROSCOPIO**********************
    var dadosGiro: [Double] = []
    var dadosGiroY: Double?
    var dadosGiroX: Double?
    var dadosGiroZ: Double?
    
    func getGyroscopeData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let yVal = Double(dataFromSensor[0]) * 500 / 65536 * -1
        let xVal = Double(dataFromSensor[1]) * 500 / 65536
        let zVal = Double(dataFromSensor[2]) * 500 / 65536
        //return [xVal, yVal, zVal]
        dadosGiro = [yVal, xVal, zVal]
        //dadosGiroY = dadosGiro[0]
        //dadosGiroX = dadosGiro[1]
        //dadosGiroZ = dadosGiro[2]
        //return dadosGiro
        return [xVal, yVal, zVal]
    }
    
    //*************************************INTERVALOS********************************************
    
    func checkLight(curChar : CBCharacteristic) {
        Timer.scheduledTimer(withTimeInterval: pickerSelecionado, repeats: true) { (timer) in
            self.myPeripheral!.readValue(for: curChar)
            print(self.pickerSelecionado)
        }
    }
    
    func checkMovement(curChar : CBCharacteristic){
        Timer.scheduledTimer(withTimeInterval: pickerSelecionado, repeats: true) { (timer) in
            self.myPeripheral!.readValue(for: curChar)
            print(self.pickerSelecionado)
        }
    }
    
    func checkHumidity(curChar : CBCharacteristic){
        Timer.scheduledTimer(withTimeInterval: pickerSelecionado, repeats: true) { (timer) in
            self.myPeripheral!.readValue(for: curChar)
            print(self.pickerSelecionado)
        }
    }
    
    
    //*******************************************************************************************
    
    var accXDouble: Double = 0
    var accYDouble: Double = 0
    var accZDouble: Double = 0
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == charHumidityData {
            let humVal = getRelativeHumidity(value: characteristic.value! as NSData)
            
            for element in humTemp{
                
                print(tempVal1)
                
                lblHum.text = "\(umidValC) kg/m³"
                
                if tempVal1 != -50 {
                    var tempVal11: String = String(format: "%.2f",tempVal1)
                    tmpLbl.text = String(" \(tempVal11) °C")
                }
                if tempVal1 > 24{
                    tempImg.image = UIImage(named: "high-temperature")
                }else if tempVal1 <= 24 {
                    tempImg.image = UIImage(named: "low-temperature")
                }
            }
        }
        
        if characteristic.uuid == charLightData {
            let luxVal = luxConvert(value: (characteristic.value! as NSData) as Data)
            
            //var baseLuz = pickerLuz
            luminosidade = Double(luxVal)
            luzLbl.text = String(format: "%.2f", luxVal)
            if luxVal > 40 {
                trainHorn.stop()
                luzImg.image = UIImage(named: "sun")
                luz = luxVal
            }else{
                trainHorn.play()
                luzImg.image = UIImage(named: "cloudy (1)")
                luz = luxVal
            }
        }
            
            
            
        else if characteristic.uuid == movementData {
            
            let dataLength = characteristic.value!.count / MemoryLayout<Int16>.size
            var dataArray = [Int16](repeating: 0, count: dataLength)
            (characteristic.value! as NSData).getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
            
            
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            let seconds = calendar.component(.second, from: date)
            let nanoseconds = calendar.component(.nanosecond, from: date)
            let currentTime = "\(hour):\(minutes):\(seconds):\(nanoseconds)"
            let dataFromSensor = dataToSignedBytes16(value: characteristic.value as NSData!)
            print(dataFromSensor)
            
            let rawGyroX:Int16 = dataFromSensor[0]
            let GyroX = Float(rawGyroX) / (65536 / 500)
            var gyroXConv = Int(GyroX)
            giroLblX.text = String("X: \(gyroXConv)")
            dadosGiroX = Double(GyroX)
            
            let rawGyroY:Int16 = dataFromSensor[1]
            let GyroY = Float(rawGyroY) / (65536 / 500)
            var gyroYConv = Int(GyroY)
            giroLblY.text = String("Y: \(gyroYConv)")
            dadosGiroY = Double(GyroY)
            
            let rawGyroZ:Int16 = dataFromSensor[2]
            let GyroZ = Float(rawGyroZ) / (65536 / 500);
            var gyroZConv = Int(GyroZ)
            giroLblZ.text = String("Z: \(gyroZConv)")
            dadosGiroZ = Double(GyroZ)
            
            
            let rawAccX:Int16 = dataFromSensor[3]
            let AccX = Float(rawAccX) / (32768/16)
            accXDouble = Double(AccX)
            var accXConv = Int(AccX)
            aceleLblX.text = String("X: \(accXConv)")
            //DOUBLE:
            //aceleLblX.text = String("\(AccX)")
            
            let rawAccY:Int16 = dataFromSensor[4]
            let AccY = Float(rawAccY) / (32768/16)
            accYDouble = Double(AccY)
            var accYConv = Int(AccY)
            aceleLblY.text = String("Y: \(accYConv)")
            //aceleLblY.text = String("\(AccY)")
            
            let rawAccZ:Int16 = dataFromSensor[5]
            let AccZ = Float(rawAccZ) / (32768/16)
            accZDouble = Double(AccZ)
            var accZConv = Int(AccZ)
            aceleLblZ.text = String("Z: \(accZConv)")
            //aceleLblZ.text = String("\(AccZ)")
            
            let rawMagX:Int16 = dataFromSensor[6]
            let MagX = Float(rawMagX)
            var magXConv = Int(MagX)
            magnetLblX.text = String("X: \(magXConv)")
            xMagVal = Double(MagX)
            
            let rawMagY:Int16 = dataFromSensor[7]
            let MagY = Float(rawMagY)
            var magYConv = Int(MagY)
            magnetLblY.text = String("Y: \(magYConv)")
            yMagVal = Double(MagY)
            
            
            let rawMagZ:Int16 = dataFromSensor[8]
            let MagZ = Float(rawMagZ)
            var magZConv = Int(MagZ)
            magnetLblZ.text = String("Z: \(magZConv)")
            zMagVal = Double(MagZ)
        }
        
    }
}
///////////////////////////////PICKER INTERVALO///////////////////////////////
extension ViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return time[row]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return time.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //        centralManager.cancelPeripheralConnection(myPeripheral)
        //        timeTextField.text = time[row]
        //        pickerSelecionado = Double(timeTextField.text!)!
        //        print(pickerSelecionado)
        //        self.view.endEditing(true)
    }
}
