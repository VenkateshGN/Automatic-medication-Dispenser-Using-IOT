import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MedicationDispenserApp extends StatefulWidget {
  @override
  _MedicationDispenserAppState createState() => _MedicationDispenserAppState();
}

class _MedicationDispenserAppState extends State<MedicationDispenserApp> {
  // Specific UUIDs to match ESP32
  static const String SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0";
  static const String CHARACTERISTIC_UUID = "87654321-4321-8765-4321-fedcba987654";

  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  List<MedicationNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    // Ensure Bluetooth is on
    await FlutterBluePlus.turnOn();
    
    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Look for our specific device
        if (r.device.platformName == "MedicationDispenser") {
          _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      // Stop scanning
      await FlutterBluePlus.stopScan();

      // Connect to the device
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find our specific service and characteristic
      for (BluetoothService service in services) {
        if (service.uuid == Guid(SERVICE_UUID)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(CHARACTERISTIC_UUID)) {
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              
              // Listen for incoming notifications
              characteristic.value.listen((value) {
                if (value.isNotEmpty) {
                  _handleNotification(String.fromCharCodes(value));
                }
              });
            }
          }
        }
      }

      setState(() {
        _connectedDevice = device;
      });
    } catch (e) {
      print('Connection error: $e');
    }
  }

  void _handleNotification(String message) {
    setState(() {
      _notifications.insert(0, MedicationNotification(
        message: message,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medication Dispenser'),
      ),
      body: Column(
        children: [
          // Connection Status
          Card(
            child: ListTile(
              title: Text(
                _connectedDevice != null 
                  ? 'Connected: ${_connectedDevice!.platformName}' 
                  : 'Searching for Medication Dispenser...'
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                MedicationNotification notification = _notifications[index];
                return ListTile(
                  title: Text(notification.message),
                  subtitle: Text(notification.timestamp.toString()),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class MedicationNotification {
  final String message;
  final DateTime timestamp;

  MedicationNotification({
    required this.message,
    required this.timestamp,
  });
}

void main() {
  runApp(MaterialApp(
    home: MedicationDispenserApp(),
  ));
}
