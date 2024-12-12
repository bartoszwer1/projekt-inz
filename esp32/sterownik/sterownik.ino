#include <WiFi.h>
#include <WebServer.h>
#define FASTLED_INTERNAL
#include <FastLED.h>
#include <math.h>

// Konfiguracja WiFi
const char* ssid = "Play_2.4Ghz";
const char* password = "Z12xc34vb5";

// Konfiguracja LED
#define LED_PIN     3
#define LED_COUNT   5
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB
CRGB leds[LED_COUNT];

// Pin fotorezystora (ADC)
#define LDR_PIN 11

// Tryby działania
enum Mode { NORMAL, ALARM, EVACUATION };
Mode currentMode = NORMAL;

// Ostatnia akcja
enum LastAction { ACTION_ROOM, ACTION_BUILDING };
LastAction lastAction = ACTION_ROOM;

// Ustawienia pomieszczeń [CCT, Jasność]
int roomSettings[LED_COUNT][2] = {
  {3000, 50},
  {4000, 50},
  {5000, 50},
  {6000, 50},
  {7000, 50}
};

// Ustawienia budynku
int buildingCct = 5000;
int buildingBrightness = 50;

// Konwersja CCT na RGB
void cctToRGB(int cct, int brightness, uint8_t &r, uint8_t &g, uint8_t &b) {
  float scale = (brightness / 100.0) * 255.0;
  float temperature = cct / 100.0;
  float red, green, blue;

  if (temperature <= 66) {
    red = 255;
  } else {
    red = temperature - 60;
    red = 329.698727446 * pow(red, -0.1332047592);
    red = constrain(red, 0, 255);
  }

  if (temperature <= 66) {
    green = temperature;
    green = 99.4708025861 * log(green) - 161.1195681661;
    green = constrain(green, 0, 255);
  } else {
    green = temperature - 60;
    green = 288.1221695283 * pow(green, -0.0755148492);
    green = constrain(green, 0, 255);
  }

  if (temperature >= 66) {
    blue = 255;
  } else {
    if (temperature <= 19) {
      blue = 0;
    } else {
      blue = temperature - 10;
      blue = 138.5177312231 * log(blue) - 305.0447927307;
      blue = constrain(blue, 0, 255);
    }
  }

  r = (uint8_t)(red   * (scale / 255.0));
  g = (uint8_t)(green * (scale / 255.0));
  b = (uint8_t)(blue  * (scale / 255.0));
}

WebServer server(80);

// Obsługa ustawienia pomieszczenia
void handleSetRoom() {
  if (!server.hasArg("room") || !server.hasArg("cct") || !server.hasArg("brightness")) {
    server.send(400, "text/plain", "Missing parameters");
    return;
  }

  int room = server.arg("room").toInt();
  int cct = server.arg("cct").toInt();
  int brightness = server.arg("brightness").toInt();

  if (room < 0 || room >= LED_COUNT) {
    server.send(400, "text/plain", "Invalid room");
    return;
  }

  cct = constrain(cct, 2300, 7500);
  brightness = constrain(brightness, 0, 100);

  roomSettings[room][0] = cct;
  roomSettings[room][1] = brightness;

  currentMode = NORMAL;
  lastAction = ACTION_ROOM;

  Serial.printf("Ustawiono Pomieszczenie %d: CCT=%dK, Jasność=%d%%\n", room + 1, cct, brightness);

  server.send(200, "text/plain", "OK");
}

// Obsługa ustawienia budynku
void handleSetBuilding() {
  if (!server.hasArg("cct") || !server.hasArg("brightness")) {
    server.send(400, "text/plain", "Missing parameters");
    return;
  }

  int cct = server.arg("cct").toInt();
  int brightness = server.arg("brightness").toInt();

  cct = constrain(cct, 2300, 7500);
  brightness = constrain(brightness, 0, 100);

  buildingCct = cct;
  buildingBrightness = brightness;

  currentMode = NORMAL;
  lastAction = ACTION_BUILDING;

  Serial.printf("Ustawiono Budynek: CCT=%dK, Jasność=%d%%\n", cct, brightness);

  server.send(200, "text/plain", "OK");
}

// Obsługa trybu Alarm
void handleAlarm() {
  currentMode = ALARM;
  Serial.println("Tryb: ALARM");
  server.send(200, "text/plain", "ALARM");
}

// Obsługa trybu Ewakuacja
void handleEvacuation() {
  currentMode = EVACUATION;
  Serial.println("Tryb: EVACUATION");
  server.send(200, "text/plain", "EVACUATION");
}

// Obsługa trybu Normal
void handleNormal() {
  currentMode = NORMAL;
  Serial.println("Tryb: NORMAL");
  server.send(200, "text/plain", "NORMAL");
}

// Obsługa root
void handleRoot() {
  server.send(200, "text/plain", "ESP32 LED Controller");
}

// Obsługa odczytu fotorezystora
void handleLight() {
  int raw = analogRead(LDR_PIN); // Zakres 0-4095 (ADC 12-bit)
  float percent = (raw / 4095.0) * 100.0;
  percent = constrain(percent, 0.0, 100.0);

  Serial.printf("Odczyt LDR: %d (%0.2f%%)\n", raw, percent);

  String json = "{ \"light\": " + String((int)percent) + " }";
  server.send(200, "application/json", json);
}

unsigned long lastAnimUpdate = 0;
bool alarmState = false; 
int evacStep = 0;

// Aktualizacja LED w trybie Normal
void updateLEDsNormal() {
  if (lastAction == ACTION_ROOM) {
    for (int i = 0; i < LED_COUNT; i++) {
      uint8_t r, g, b;
      cctToRGB(roomSettings[i][0], roomSettings[i][1], r, g, b);
      leds[i] = CRGB(r, g, b);
    }
  } else {
    uint8_t r, g, b;
    cctToRGB(buildingCct, buildingBrightness, r, g, b);
    for (int i = 0; i < LED_COUNT; i++) {
      leds[i] = CRGB(r, g, b);
    }
  }
  FastLED.show();
}

// Aktualizacja LED w trybie Alarm
void updateLEDsAlarm() {
  unsigned long now = millis();
  if (now - lastAnimUpdate > 1000) {
    lastAnimUpdate = now;
    alarmState = !alarmState;
  }

  for (int i = 0; i < LED_COUNT; i++) {
    leds[i] = alarmState ? CRGB::Red : CRGB::Black;
  }
  FastLED.show();
}

// Aktualizacja LED w trybie Ewakuacja
void updateLEDsEvacuation() {
  unsigned long now = millis();
  if (now - lastAnimUpdate > 500) {
    lastAnimUpdate = now;
    evacStep = (evacStep + 1) % LED_COUNT;
  }

  for (int i = 0; i < LED_COUNT; i++) {
    if (i == evacStep) {
      leds[i] = CRGB::Green;
    } else {
      leds[i] = CRGB(0, 30, 0);
    }
  }
  FastLED.show();
}

void setup() {
  Serial.begin(115200);
  FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, LED_COUNT);
  FastLED.setBrightness(255); 

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected, IP: " + WiFi.localIP().toString());

  // Definicja endpointów
  server.on("/", handleRoot);
  server.on("/set", handleSetRoom);
  server.on("/setBuilding", handleSetBuilding);
  server.on("/alarm", handleAlarm);
  server.on("/evacuation", handleEvacuation);
  server.on("/normal", handleNormal);
  server.on("/light", handleLight);

  server.begin();
}

void loop() {
  server.handleClient();

  // Aktualizacja LED w zależności od trybu
  switch (currentMode) {
    case NORMAL:
      updateLEDsNormal();
      break;
    case ALARM:
      updateLEDsAlarm();
      break;
    case EVACUATION:
      updateLEDsEvacuation();
      break;
  }
}