#include <WiFi.h>
#include <WebServer.h>
#define FASTLED_INTERNAL
#include <FastLED.h>
#include <math.h>

// Konfiguracja WiFi
const char* ssid = "TWOJ_SSID";
const char* password = "TWOJE_HASLO";

// Konfiguracja LED
#define LED_PIN     3
#define LED_COUNT   5
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB
CRGB leds[LED_COUNT];

// Tryby pracy
enum Mode { NORMAL, ALARM, EVACUATION };
Mode currentMode = NORMAL;

// Ostatnia akcja w trybie NORMAL: room czy building?
enum LastAction { ACTION_ROOM, ACTION_BUILDING };
LastAction lastAction = ACTION_ROOM;

// Parametry pomieszczen: roomSettings[i][0] = cct, roomSettings[i][1] = brightness
int roomSettings[LED_COUNT][2] = {
  {3000, 50},
  {4000, 50},
  {5000, 50},
  {6000, 50},
  {7000, 50}
};

// Parametry globalne budynku
int buildingCct = 5000;
int buildingBrightness = 50;

// Funkcja do konwersji CCT na RGB
void cctToRGB(int cct, int brightness, uint8_t &r, uint8_t &g, uint8_t &b) {
  float scale = (brightness / 100.0) * 255.0;
  float temperature = cct / 100.0;
  float red, green, blue;

  // Red
  if (temperature <= 66) {
    red = 255;
  } else {
    red = temperature - 60;
    red = 329.698727446 * pow(red, -0.1332047592);
    if (red < 0) red = 0;
    if (red > 255) red = 255;
  }

  // Green
  if (temperature <= 66) {
    green = temperature;
    green = 99.4708025861 * log(green) - 161.1195681661;
    if (green < 0) green = 0;
    if (green > 255) green = 255;
  } else {
    green = temperature - 60;
    green = 288.1221695283 * pow(green, -0.0755148492);
    if (green < 0) green = 0;
    if (green > 255) green = 255;
  }

  // Blue
  if (temperature >= 66) {
    blue = 255;
  } else {
    if (temperature <= 19) {
      blue = 0;
    } else {
      blue = temperature - 10;
      blue = 138.5177312231 * log(blue) - 305.0447927307;
      if (blue < 0) blue = 0;
      if (blue > 255) blue = 255;
    }
  }

  r = (uint8_t)(red   * (scale/255.0));
  g = (uint8_t)(green * (scale/255.0));
  b = (uint8_t)(blue  * (scale/255.0));
}

WebServer server(80);

// Funkcje obsługi HTTP
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

  if (cct < 2300) cct = 2300;
  if (cct > 7500) cct = 7500;
  if (brightness < 0) brightness = 0;
  if (brightness > 100) brightness = 100;

  roomSettings[room][0] = cct;
  roomSettings[room][1] = brightness;

  // Zmiana trybu na NORMAL i ostatnia akcja = room
  currentMode = NORMAL;
  lastAction = ACTION_ROOM;

  server.send(200, "text/plain", "OK");
}

void handleSetBuilding() {
  if (!server.hasArg("cct") || !server.hasArg("brightness")) {
    server.send(400, "text/plain", "Missing parameters");
    return;
  }

  int cct = server.arg("cct").toInt();
  int brightness = server.arg("brightness").toInt();

  if (cct < 2300) cct = 2300;
  if (cct > 7500) cct = 7500;
  if (brightness < 0) brightness = 0;
  if (brightness > 100) brightness = 100;

  buildingCct = cct;
  buildingBrightness = brightness;

  currentMode = NORMAL;
  lastAction = ACTION_BUILDING;

  server.send(200, "text/plain", "OK");
}

void handleAlarm() {
  currentMode = ALARM;
  server.send(200, "text/plain", "ALARM");
}

void handleEvacuation() {
  currentMode = EVACUATION;
  server.send(200, "text/plain", "EVACUATION");
}

void handleNormal() {
  currentMode = NORMAL;
  server.send(200, "text/plain", "NORMAL");
}

void handleRoot() {
  server.send(200, "text/plain", "ESP32 LED Controller");
}

// Zmienne do animacji
unsigned long lastAnimUpdate = 0;
bool alarmState = false; // dla alarmu miganie
int evacStep = 0;        // dla ewakuacji

void updateLEDsNormal() {
  if (lastAction == ACTION_ROOM) {
    // Używamy ustawień indywidualnych
    for (int i = 0; i < LED_COUNT; i++) {
      uint8_t r,g,b;
      cctToRGB(roomSettings[i][0], roomSettings[i][1], r, g, b);
      leds[i] = CRGB(r,g,b);
    }
  } else {
    // Używamy ustawień globalnych
    uint8_t r,g,b;
    cctToRGB(buildingCct, buildingBrightness, r, g, b);
    for (int i = 0; i < LED_COUNT; i++) {
      leds[i] = CRGB(r,g,b);
    }
  }
  FastLED.show();
}

void updateLEDsAlarm() {
  // Co sekundę zmieniamy stan diod między czerwonym a zgaszonym
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

void updateLEDsEvacuation() {
  // Co ~500 ms przesuwamy zielony punkt
  unsigned long now = millis();
  if (now - lastAnimUpdate > 500) {
    lastAnimUpdate = now;
    evacStep = (evacStep + 1) % LED_COUNT;
  }

  // W evac mode - jeden LED mocno zielony, reszta lekko zielona
  for (int i = 0; i < LED_COUNT; i++) {
    if (i == evacStep) {
      leds[i] = CRGB::Green;
    } else {
      leds[i] = CRGB(0,50,0); // ciemniejszy zielony
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

  server.on("/", handleRoot);
  server.on("/set", handleSetRoom);
  server.on("/setBuilding", handleSetBuilding);
  server.on("/alarm", handleAlarm);
  server.on("/evacuation", handleEvacuation);
  server.on("/normal", handleNormal);

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