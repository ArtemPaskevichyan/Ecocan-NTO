//
//  BluetoothViewModel.swift
//  EcoPlan Diagnostics
//
//  Created by Artem Paskevichyan on 08.03.2022.
//

import Foundation
import CoreBluetooth
import SwiftUI
import PDFKit


struct DeviceData: Identifiable {
    var name: String?
    var id: UUID
}

struct BLEError: Identifiable {
    var id = UUID()
    var text: String
    
    init(_ st: String) {
        text = st
    }
}

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var peripherals = [CBPeripheral]()
    private var characteristicUUID = CBUUID(string: "FFE1")
    private var serviceUUID = CBUUID(string: "FFE0")
    private var writeCharacteristic: CBCharacteristic?
    private var mainDevice: CBPeripheral?
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    private var wantToScan = false
    private var responseHandler: String {
        get {
            requestAnswer
        }
        set {
            showResponse = !showResponse
            requestAnswer = newValue
        }
    }
    
    @Published var manager = CBCentralManager()
    @Published var devicesArray = [DeviceData]()
    @Published var devicesArrayMatches = [DeviceData]()
    @Published var devicesArrayElse = [DeviceData]()
    @Published var isScannig: Bool = false
    @Published var deviceUnlocked: Bool = false
    @Published var isConnecting: Bool = false
    @Published var isConnectionSuccessful: Bool?
    @Published var errorList = [BLEError]()
    @Published var requestAnswer: String = "200"
    @Published var showResponse: Bool = false
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: .main)
        getDevicesList()
    }
    
    func getDevicesList() {
        if !manager.isScanning {
            print("IS SCANNING")
            self.devicesArray = []
            self.devicesArrayMatches = []
            self.devicesArrayElse = []
            self.peripherals = []
            
            wantToScan = true
            self.manager.scanForPeripherals(withServices: nil, options: nil)
            self.isScannig = self.manager.isScanning
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                self.stopScanning()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let cloneArray = devicesArray.filter { device in
            device.id == peripheral.identifier
        }
        if cloneArray.count == 0 {
            let element = DeviceData(name: peripheral.name, id: peripheral.identifier)
            peripherals.append(peripheral)
            devicesArray.append(element)
            
            if let name = element.name {
                if name.starts(with: "ECN") {
                    devicesArrayMatches.append(element)
                } else {
                    devicesArrayElse.append(element)
                }
            } else {
                devicesArrayElse.append(element)
            }
        }
    }
    
    func stopScanning() {
        manager.stopScan()
        isScannig = manager.isScanning
    }
    
    func createPDF(id: String, m0: Bool, m1: Bool, m2: Bool, t0: Bool, t1: Bool, t2: Bool, f0: Bool, f1: Bool, f2: Bool) {
        func createFlyer() -> Data {
          // 1
          let pdfMetaData = [
            kCGPDFContextCreator: "Flyer Builder",
            kCGPDFContextAuthor: "raywenderlich.com"
          ]
          let format = UIGraphicsPDFRendererFormat()
          format.documentInfo = pdfMetaData as [String: Any]

          // 2
          let pageWidth = 8.5 * 72.0
          let pageHeight = 11 * 72.0
          let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

          // 3
          let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
          // 4
          let data = renderer.pdfData { (context) in
            // 5
            context.beginPage()
            // 6
            let attributes = [
              NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 72)
            ]
            let text = createResponse(m0: m0, m1: m1, m2: m2, t0: t0, t1: t1, t2: t2, f0: f0, f1: f1, f2: f2, splitter: "\r")
            text.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
          }

          return data
        }

    }
    
    func sendResponse(id: String, m0: Bool, m1: Bool, m2: Bool, t0: Bool, t1: Bool, t2: Bool, f0: Bool, f1: Bool, f2: Bool) {
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NDc0Mzg3NTMsInVzZXIiOiJBZG1pbiJ9.nyxpKqYsahE6jqdHq_xL7GuBSituvoIEqW8IzyWTfWbKAXj4PmdTu4_RDVPfqawGsG7M4BrNT9r-10mj1Z2PDw"
        guard let url = URL(string: "https://api.computernetthings.space/close_point") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(token, forHTTPHeaderField: "token")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var response = ""
        let faults = [m0, m1, m2, t0, t1, t2, f0, f1, f2].filter { $0 }
        if faults.count == 0 {
            response = "Вердикт: Усройство неисправно"
        } else {
            response = "Вердикт: Устройство исправно;Пункт закрыт"
        }
        
        let jsonPack:[String: AnyHashable] = [
            "id": Int(id)!,
            "set_status": response,
            "is_closed": false
        ]
        
        print(jsonPack)
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonPack, options: .fragmentsAllowed)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorList.append(BLEError("Request: \(error?.localizedDescription ?? "Error is nil")"))
                    print(error?.localizedDescription ?? "Error is nil")
                    self.responseHandler = error?.localizedDescription ?? "Error is nil"
                }
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print(response.statusCode)
                DispatchQueue.main.async {
                    self.responseHandler = String(response.statusCode)
                }
            } else {
                DispatchQueue.main.async {
                    self.errorList.append(BLEError("Request: Empty response"))
                    print("Empty response")
                    self.responseHandler = "Empty response"
                }
                return
            }
        }
        
        task.resume()
    }
    
    func changeDeviceUnlocked() {
        deviceUnlocked = !deviceUnlocked
    }
    
    func createResponse(m0: Bool, m1: Bool, m2: Bool, t0: Bool, t1: Bool, t2: Bool, f0: Bool, f1: Bool, f2: Bool, splitter: String) -> String {
        var response = ""

        response += "Состояние сервоприводов: " + splitter
        response += "Серво 1:" + (m0 ? "Испр." : "Неиспр.") + splitter
        response += "Серво 2:" + (m1 ? "Испр." : "Неиспр.") + splitter
        response += "Серво 3:" + (m2 ? "Испр." : "Неиспр.") + splitter
        response += "Состояние датчиков цвета: " + splitter
        response += "Цвет 1:" + (t0 ? "Испр." : "Неиспр.") + splitter
        response += "Цвет 2:" + (t1 ? "Испр." : "Неиспр.") + splitter
        response += "Цвет 3:" + (t2 ? "Испр." : "Неиспр.") + splitter
        response += "Состояние датчиков расстояния: " + splitter
        response += "Расстояние 1:" + (f0 ? "Испр." : "Неиспр.") + splitter
        response += "Расстояние 2:" + (f1 ? "Испр." : "Неиспр.") + splitter
        response += "Расстояние 3:" + (f2 ? "Испр." : "Неиспр.") + splitter
        
        let faults = [m0, m1, m2, t0, t1, t2, f0, f1, f2].filter { $0 }
        if faults.count == 0 {
            response += "Вердикт: Усройство неисправно"
        } else {
            response += "Вердикт: Устройство исправно"
        }
        
        return response
    }
    
    func hasAccess() -> Bool {
        if CBCentralManager.authorization == .allowedAlways {
            return true
        } else {
            return false
        }
    }
    
    func redirectToSettings() {
        if let url = URL.init(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
         case .unknown:
            print("central.state is .unknown")
         case .resetting:
            print("central.state is .resetting")
         case .unsupported:
            print("central.state is .unsupported")
         case .unauthorized:
            print("central.state is .unauthorized")
         case .poweredOff:
            print("central.state is .poweredOff")
         case .poweredOn:
            print("central.state is .poweredOn")
            if wantToScan && !manager.isScanning{
                getDevicesList()
            }
        @unknown default:
            fatalError()
        }
    }
    
    func connectToDevice(withID id: UUID) {
        isConnecting = true
        disconnect()
        isConnectionSuccessful = nil
        if peripherals.isEmpty {
            errorList.append(BLEError("Device: No scanned device picked"))
            return
        }
        
        let filterList = peripherals.filter { $0.identifier == id }
        if filterList.isEmpty {
            errorList.append(BLEError("Device: There is no device with same id in scanned device"))
            return
        }
        
        mainDevice = filterList[0]
        manager.connect(mainDevice!, options: nil)
        mainDevice!.delegate = self
        sendStringToDevice("S")
    }
    
    
    func disconnect() {
        if mainDevice != nil {
            manager.cancelPeripheralConnection(mainDevice!)
        } else {
            errorList.append(BLEError("Connection: Can't disconnect from device, connected device is nil"))
            print("Can't disconnect from device, connected device is nil")
            return
        }
        deviceUnlocked = false
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnecting = false
        peripheral.discoverServices([serviceUUID])
        print("Connection: Connected to device")
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        deviceUnlocked = false
        print("Disconnected")
        errorList.append(BLEError("Connection: Disconnected \(peripheral.name ?? peripheral.identifier.uuidString) \n \(error?.localizedDescription ?? "Unrecognized Error")"))
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnecting = false
        isConnectionSuccessful = false
        print("Connection is Failed")
        errorList.append(BLEError("Connection: Connection is failed"))
    }
    
     
    func sendStringToDevice(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            errorList.append(BLEError("Cant Send Data: Wrong data type"))
            print("Wrond data type")
            return
        }
        if mainDevice == nil {
            errorList.append(BLEError("Cant Send Data: There are no device where can send data"))
            print("There are no device where can send data")
            return
        }
        if writeCharacteristic == nil {
            errorList.append(BLEError("Cant Send Data: Device has no characteristic with needed name"))
            print("Device has no characteristic with needed name")
            return
        }
        mainDevice!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        var flag = true
        for service in peripheral.services! {
            flag = false
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
        if flag {
            errorList.append(BLEError("Servises: Device has no service with needed name"))
            print("Device has no service with needed name")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("SOMETHIIIING")
        var flag = true
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                
                flag = false
                writeCharacteristic = characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
            }
        }
        if flag {
            errorList.append(BLEError("Characteristic: Device has no characteristic with needed name"))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        guard let stringData = String(data: value, encoding: .utf8) else { return }
        switch stringData {
        case "k1":
            deviceUnlocked = true
        case "k0":
            deviceUnlocked = false
        default:
            return
        }
    }
    
    
}
