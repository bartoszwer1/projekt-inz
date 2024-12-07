#include <WiFi.h>
#include <WebServer.h>
#define FASTLED_INTERNAL
#include <FastLED.h>

// Konfiguracja WiFi
const char* ssid = "B99";
const char* password = "32*084KL3sz";

// Konfiguracja LED
#define LED_PIN     3
#define LED_COUNT   5
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB

CRGB leds[LED_COUNT];

WebServer server(80);

// Przechowywanie aktualnych ustawień dla każdego pokoju
// roomSettings[i][0] = cct, roomSettings[i][1] = brightness
int roomSettings[LED_COUNT][2] = {
  {3000, 50},
  {4000, 50},
  {5000, 50},
  {6000, 50},
  {7000, 50}
};

// Funkcja do konwersji CCT na RGB (przybliżona)
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

void updateLEDs() {
  for (int i = 0; i < LED_COUNT; i++) {
    uint8_t r, g, b;
    cctToRGB(roomSettings[i][0], roomSettings[i][1], r, g, b);
    leds[i] = CRGB(r, g, b);
  }
  FastLED.show();
}

void handleSet() {
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

  updateLEDs();
  server.send(200, "text/plain", "OK");
}

void handleRoot() {
  server.send(200, "text/html", "<h1>ESP32 LED Controller</h1><p>Use /set?room=[0-4]&cct=[2300-7500]&brightness=[0-100]</p>");
}

void setup() {
  Serial.begin(115200);

  FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, LED_COUNT);
  FastLED.setBrightness(255); // Maks jasność sterujemy i tak procentowo w cctToRGB

  updateLEDs();

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected, IP: " + WiFi.localIP().toString());

  server.on("/", handleRoot);
  server.on("/set", handleSet);

  server.begin();
}

void loop() {
  server.handleClient();
}