#define TESTING 0     // test mode (random values)
#define DEBUG 0       // debug mode

char sep[] = "|";
int voltage12Pin = A1;  // voltage 12V
int voltage5Pin = A2;   // voltage 5V
int current12Pin = A4;  // current 12V
int current5Pin = A5;   // current 5V
int samples = 100;      // number of samples
unsigned long timeTotal = 0;
 
void setup() {
  #if TESTING
     randomSeed(analogRead(0));
  #endif
  
  Serial.begin(115200);
  delay(100);
}

void loop() {
  unsigned long timeStart = millis();
  float rand12V = 0;
  float rand5V = 0;
  float rand12A = 0;
  float rand5A = 0;  
  Serial.flush();
  delay(200);        // a lot of Serial noise without delay or with smaller values

  for(int i=0; i<samples; i++)
  {
    rand12V = rand12V + (analogRead(voltage12Pin) * 0.01450);      // calculate 12V voltage
    rand5V = rand5V + (analogRead(voltage5Pin) * 0.01474);         // calculate 5V voltage
    //rand12V = rand12V + (voltage12Val * 2.97);           
    rand12A = rand12A + (.0264 * analogRead(current12Pin) -13.51); // calculate 12V current            
    rand5A = rand5A + (.0264 * analogRead(current5Pin) -13.51);    // calculate 5V current
    //rand5A = rand5A + (current5Val-2.5)/0.185;      
    delay(1);
  }
  rand12V = rand12V/samples;
  rand5V = rand5V/samples;
  rand12A = rand12A/samples;
  rand5A = rand5A/samples;
  
  #if TESTING
    rand12V = random(1100, 1220) / 100.00;
    rand5V = random(450, 550) / 100.00;
    rand12A = random(50, 150) / 100.00;
    rand5A = random(50, 150) / 100.00;
  #endif
  
  #if DEBUG
    Serial.print("Voltage 12V: ");
    Serial.println(rand12V, 3); 
    Serial.print("Voltage 5V: ");
    Serial.println(rand5V, 3); 
    Serial.print("Current 12V: ");
    Serial.println(rand12A, 3); 
    Serial.print("Current 5V: ");
    Serial.println(rand5A, 3); 
    Serial.print("Time: ");
    timeTotal = timeTotal + millis() - timeStart;
    Serial.println(timeTotal);
    Serial.println();
  #else
    Serial.print(rand12V, 3);
    Serial.print(sep);
    Serial.print(rand5V, 3);
    Serial.print(sep);
    Serial.print(rand12A, 3);
    Serial.print(sep);
    Serial.print(rand5A, 3);
    Serial.print(sep);
    timeTotal = timeTotal + millis() - timeStart;
    Serial.print(timeTotal);
    Serial.println(sep);
  #endif
}
