const int inputPin = 9;   // Digital pin to read the contact signal
const int OUTPUT_TO_DAQ = 10;  // Digital pin to output TTL pulse
const int OUTPUT_TO_MATLABARDU = 11; 

bool prevInput = LOW;      // Track previous contact state

void setup() {
  Serial.begin(9600);                // For debugging, optional
  pinMode(inputPin, INPUT);          // INPUT mode (use INPUT_PULLUP if no external pull-up resistor)
  pinMode(OUTPUT_TO_DAQ, OUTPUT);        // Output TTL 
  pinMode(OUTPUT_TO_MATLABARDU, OUTPUT);
  digitalWrite(OUTPUT_TO_DAQ, LOW);      // Ensure output starts low
  digitalWrite(OUTPUT_TO_MATLABARDU, LOW); 
}

void loop() {
  bool currInput = digitalRead(inputPin);  // Read current contact state

  if (currInput == HIGH && prevInput == LOW) {
    // Rising edge detected → contact began
    digitalWrite(OUTPUT_TO_DAQ, HIGH);
    digitalWrite(OUTPUT_TO_MATLABARDU, HIGH);
    delay(1);                          // Pulse duration (1 ms)
    digitalWrite(OUTPUT_TO_DAQ, LOW);
    // digitalWrite(outputPinTOMatlab, LOW);
  }
  if (currInput == LOW) {
    digitalWrite(OUTPUT_TO_MATLABARDU, LOW);
  }

  Serial.println(currInput);   // Optional debug print
  prevInput = currInput;  // Update state for next cycle
  delay(1);               // Sampling interval (1 ms)
}
