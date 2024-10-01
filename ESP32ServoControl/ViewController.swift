import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var esp32Peripheral: CBPeripheral?

    // ESP32의 서비스 및 특성 UUID
    let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
    let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-210987654321")

    var commandCharacteristic: CBCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()

        // BLE 중앙 관리자 초기화
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // 중앙 관리자 상태 업데이트
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // BLE 장치 검색 시작 (특정 서비스 UUID로 필터링 가능)
            // 모든 BLE 장치를 검색
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Scanning for peripherals...")
        } else {
            print("Bluetooth is not available.")
        }
    }

    // BLE 장치 검색 완료 시
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 장치 이름을 확인하고, ESP32와 자동 연결
        if peripheral.name == "ESP32_BLE_Servo" {
            esp32Peripheral = peripheral
            centralManager.stopScan()  // 장치 검색 중지
            centralManager.connect(peripheral, options: nil)  // 자동 연결 시도
            print("Found ESP32, connecting...")
        }
    }

    // BLE 장치 연결 완료 시
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        esp32Peripheral = peripheral
        esp32Peripheral?.delegate = self
        esp32Peripheral?.discoverServices([serviceUUID])  // 서비스 검색

        // 연결 성공 알림 메시지 표시
        showAlert(title: "연결 성공", message: "\(peripheral.name ?? "Unknown Device")에 연결되었습니다.")
    }

    // 서비스 발견 시
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID {
                    // 서비스가 발견되면 특성 검색 시작
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
        }
    }

    // 특성 발견 시
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID {
                    // 특성 저장 (명령 전송에 사용)
                    commandCharacteristic = characteristic
                    print("Characteristic found!")
                }
            }
        }
    }

    // BLE 연결 실패 시
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device")")
        showAlert(title: "연결 실패", message: "\(peripheral.name ?? "Unknown Device")에 연결하지 못했습니다.")
    }

    // BLE 연결이 끊어졌을 때
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device")")
        showAlert(title: "연결 끊김", message: "\(peripheral.name ?? "Unknown Device")의 연결이 끊어졌습니다.")
    }

    // 명령 전송 함수
    func sendCommand(_ command: String) {
        if let characteristic = commandCharacteristic {
            let data = command.data(using: .utf8)!
            esp32Peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    // "Turn On" 명령 전송
    @IBAction func turnOnButtonTapped(_ sender: UIButton) {
        sendCommand("on")
    }

    // "Turn Off" 명령 전송
    @IBAction func turnOffButtonTapped(_ sender: UIButton) {
        sendCommand("off")
    }

    // 알림 메시지 표시 함수
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
