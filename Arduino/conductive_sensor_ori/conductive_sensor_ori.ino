// const int inputPin = 12;  // Digital pin to read input from
// const int outputPin = 11; // Digital pin to output lick info
// int time;
// void setup() {
//   // Initialize the serial communication
//   Serial.begin(31250);

//   // Set the pin mode as INPUT
//   pinMode(inputPin, INPUT); // Use INPUT_PULLUP if no external pull-up resistor is used
//   pinMode(outputPin, OUTPUT);
// }

// void loop() {
//   // Read the digital input value from pin 4
//   int inputState = digitalRead(inputPin);
//   if (inputState == 1) {
//       digitalWrite(outputPin, HIGH);
//       delay(1);
//       digitalWrite(outputPin, LOW);
//   }

//   // Print the value to the Serial Monitor
//   Serial.println(inputState);  // Will print 0 (LOW) or 1 (HIGH)

//   // Add a small delay for readability, in milliseconds
//   delay(5);   
// }


const int inputPin = 12;   // Digital pin to read the contact signal
const int outputPin = 11;  // Digital pin to output TTL pulse

bool prevInput = LOW;      // Track previous contact state

void setup() {
  Serial.begin(9600);                // For debugging, optional
  pinMode(inputPin, INPUT);          // INPUT mode (use INPUT_PULLUP if no external pull-up resistor)
  pinMode(outputPin, OUTPUT);        // Output TTL pulse
  digitalWrite(outputPin, LOW);      // Ensure output starts low
}

void loop() {
  bool currInput = digitalRead(inputPin);  // Read current contact state

  if (currInput == HIGH && prevInput == LOW) {
    // Rising edge detected → contact began
    digitalWrite(outputPin, HIGH);
    delay(1);                          // Pulse duration (1 ms)
    digitalWrite(outputPin, LOW);
  }

  Serial.println(currInput);   // Optional debug print
  prevInput = currInput;  // Update state for next cycle
  delay(1);               // Sampling interval (1 ms)
}
