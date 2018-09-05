



int LEDin = 21;
int LEDout = 4;

int LEDsignal = 0;
float dc = 0;

float period = .5; //cycle length in milliseconds
float periodus = 1000*period; //cycle length in microseconds

void setup() {

pinMode(LEDin, INPUT);
pinMode(LEDout, OUTPUT);

digitalWrite(LEDout, LOW);


}

void loop() {

LEDsignal = analogRead(LEDin); //takes 100us

dc = LEDsignal*.001;

if (dc < (periodus-100)/periodus) {
  digitalWrite(LEDout, HIGH);
  delayMicroseconds(floor(periodus*dc)); // leave HIGH for dc*period us
  digitalWrite(LEDout, LOW);
  delayMicroseconds(periodus-100-floor(periodus*dc));
}
else {
  digitalWrite(LEDout, HIGH);
}
}
