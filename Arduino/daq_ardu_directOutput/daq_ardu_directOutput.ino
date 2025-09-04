#include <Arduino.h>

// Pin assignments
const int LICK_RECEIVE    = 2;
const int LED_RECEIVE     = 3;
const int SOUND_RECEIVE   = 4;
const int PORT_RECEIVE    = 11;
const int WATER_RECEIVE   = 8;
const int AIRPUFF_RECEIVE = 6;

// State tracking
bool prevLICK, prevLED, prevSOUND, prevPORT, prevWATER, prevAIRPUFF;
bool recordingStarted = false;
unsigned long trialStartTime = 0;

void setup() {
  Serial.begin(9600);
  pinMode(LICK_RECEIVE, INPUT);
  pinMode(LED_RECEIVE, INPUT);
  pinMode(SOUND_RECEIVE, INPUT);
  pinMode(PORT_RECEIVE, INPUT);
  pinMode(WATER_RECEIVE, INPUT);
  pinMode(AIRPUFF_RECEIVE, INPUT);

  // Initialize previous states
  prevLICK    = digitalRead(LICK_RECEIVE);
  prevLED     = digitalRead(LED_RECEIVE);
  prevSOUND   = digitalRead(SOUND_RECEIVE);
  prevPORT    = digitalRead(PORT_RECEIVE);
  prevWATER   = digitalRead(WATER_RECEIVE);
  prevAIRPUFF = digitalRead(AIRPUFF_RECEIVE);
}

void loop() {
  detectChange("LICK", LICK_RECEIVE, prevLICK);
  detectChange("LED", LED_RECEIVE, prevLED);
  detectChange("SOUND", SOUND_RECEIVE, prevSOUND);
  detectChange("PORT", PORT_RECEIVE, prevPORT);
  detectChange("WATER", WATER_RECEIVE, prevWATER);
  detectChange("AIRPUFF", AIRPUFF_RECEIVE, prevAIRPUFF);
  delay(1);  // Sampling interval (1 ms)
}

void detectChange(const char* label, int pin, bool &prevState) {
  bool currState = digitalRead(pin);
  if (currState != prevState) {
    unsigned long now = millis();

    // If LED just turned on, mark trial start
    if (strcmp(label, "LED") == 0 && currState == HIGH) {
      trialStartTime = now;
      recordingStarted = true;
    }

    if (recordingStarted) {
      Serial.print("EVENT:");
      Serial.print(label);
      Serial.print(",");
      Serial.print(now - trialStartTime);  // Relative time from LED ON
      Serial.print(",");
      Serial.println(currState);
    }

    prevState = currState;
  }
}
