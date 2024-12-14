#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// Pins and Medication Configuration
const int LED_PINS[] = {14, 26, 33};
const char* MEDICINE_NAMES[] = {"Aspirin", "Ibuprofen", "Vitamin D"};
const int NUM_MEDICINES = 3;

// BLE Configuration
#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "87654321-4321-8765-4321-fedcba987654"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      // Restart advertising
      BLEDevice::startAdvertising();
    }
};

void setupBLE() {
  // Initialize BLE device
  BLEDevice::init("MedicationDispenser");
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );

  // Start service and advertising
  pService->start();
  BLEDevice::startAdvertising();
}

void sendMedicationNotification(const char* medicineName) {
  if (deviceConnected) {
    // Send notification
    pCharacteristic->setValue((uint8_t*)medicineName, strlen(medicineName));
    pCharacteristic->notify();
  }
}

void setup() {
  // Initialize LED pins
  for (int i = 0; i < NUM_MEDICINES; i++) {
    pinMode(LED_PINS[i], OUTPUT);
  }

  // Setup BLE
  setupBLE();
}

void loop() {
  // Cycle through LEDs
  for (int i = 0; i < NUM_MEDICINES; i++) {
    // Turn on LED
    digitalWrite(LED_PINS[i], HIGH);
    
    // Send BLE notification
    sendMedicationNotification(MEDICINE_NAMES[i]);
    
    // LED on duration
    delay(5000);
    
    // Turn off LED
    digitalWrite(LED_PINS[i], LOW);
    
    // Delay before next medication
    delay(5000);
  }
}
