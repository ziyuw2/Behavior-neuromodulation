// // For behavior rig 5

// #include <CapacitiveSensor.h>

// // Define the send and receive pins for the capacitive sensor
// const int SENSOR_SEND = 10;
// const int SENSOR_RECEIVE = 12;

// // Create a CapacitiveSensor object
// CapacitiveSensor capSensor = CapacitiveSensor(SENSOR_SEND, SENSOR_RECEIVE);

// const int OUT_TO_LED = 3;
// const int OUT_TO_DAQUNO = 5;
// const int OUT_TO_MATLABUNO = 4;

// int prev_value = 0;
// const int THRESHOLD = 100;
// bool prevPassedThreshold = LOW;

// void setup() {
//   // Initialize the OUT_CENTER pin as an output
//   pinMode(OUT_TO_LED, OUTPUT);
//   pinMode(OUT_TO_DAQUNO, OUTPUT);
//   pinMode(OUT_TO_MATLABUNO, OUTPUT);

//   // Initialize serial communication
//   Serial.begin(9600);

//   // Optional: set the capacitive sensor to use a higher resolution measurement
//   capSensor.set_CS_AutocaL_Millis(0xFFFFFFFF);
// }

// void loop() {
//   long sensorValue = 0;
  
//   // Perform the capacitive sensing (30 samples)
//   sensorValue = capSensor.capacitiveSensor(30);
  
//   // Low pass filter
//   sensorValue = 0.9 * prev_value + 0.1 * sensorValue;
//   prev_value = 0;

//   // Print the filtered sensor value

//   // Check against the threshold and set the OUT_CENTER pin accordingly
//   if (sensorValue > THRESHOLD && prevPassedThreshold == LOW) {
//     digitalWrite(OUT_TO_LED, HIGH);
//     digitalWrite(OUT_TO_DAQUNO, HIGH);
//     digitalWrite(OUT_TO_MATLABUNO, HIGH);
//     delay(1); 
//   } else {
//     digitalWrite(OUT_TO_LED, LOW);
//     digitalWrite(OUT_TO_DAQUNO, LOW);
//     digitalWrite(OUT_TO_MATLABUNO, LOW);
//   }
//   Serial.println(sensorValue);
//   prevPassedThreshold = HIGH;
//   delay(1);
// }

#include <CapacitiveSensor.h>

// Define the send and receive pins for the capacitive sensor
const int SENSOR_SEND = 10;
const int SENSOR_RECEIVE = 12;
CapacitiveSensor capSensor = CapacitiveSensor(SENSOR_SEND, SENSOR_RECEIVE);

// Output pins
const int OUT_TO_LED = 3;
const int OUT_TO_DAQUNO = 5;
const int OUT_TO_MATLABUNO = 4;

long prev_value = 0;
const int THRESHOLD = 100;
bool prevPassedThreshold = false;

void setup() {
  pinMode(OUT_TO_LED, OUTPUT);
  pinMode(OUT_TO_DAQUNO, OUTPUT);
  pinMode(OUT_TO_MATLABUNO, OUTPUT);

  Serial.begin(9600);
  capSensor.set_CS_AutocaL_Millis(0xFFFFFFFF);
}

void loop() {
  long rawValue = capSensor.capacitiveSensor(30);

  // Low-pass filter
  long filteredValue = 0.9 * prev_value + 0.1 * rawValue;
  prev_value = filteredValue;

  // Rising edge detection
  if (filteredValue > THRESHOLD && !prevPassedThreshold) {
    digitalWrite(OUT_TO_LED, HIGH);
    digitalWrite(OUT_TO_DAQUNO, HIGH);
    digitalWrite(OUT_TO_MATLABUNO, HIGH);
    // delay(5);  // Pulse duration
    
    prevPassedThreshold = true;
  } 

  // Reset the threshold flag when below threshold
  if (filteredValue <= THRESHOLD) {
    digitalWrite(OUT_TO_LED, LOW);
    digitalWrite(OUT_TO_DAQUNO, LOW);
    digitalWrite(OUT_TO_MATLABUNO, LOW);
    prevPassedThreshold = false;
  }

  Serial.println(filteredValue);
  delay(1);
}
