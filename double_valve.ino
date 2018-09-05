                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           /*

 */
 
  int flowin = 6;  // pin 6 flow toggle (from NIDAq)
  int flowout = 10; // pin 10 flow toggle out (to relay/valves)
 
  int valve1in = 5;  // Pin 5 valve in (from NIDAq)
  int valve1out = 8;  // Pin 8  valve out

  int IRout = 2;  // Pin 2 IR LED dimmer out
  int cameraout = 3;  // Pin 3 camera out

  int valve2out = 13; // Pin 13 laser out



// the setup routine runs once when you press reset:
void setup() {                
  // initialize the digital pin as an output.
  
 
  
  pinMode(flowin, INPUT); 
  pinMode(flowout, OUTPUT); 
  
  pinMode(valve1in, INPUT);     
 
  pinMode(IRout, OUTPUT); 
  pinMode(cameraout, OUTPUT); 
  
  pinMode(valve1out, OUTPUT); 
  pinMode(valve2out, OUTPUT); 

  digitalWrite(IRout, LOW); 
  digitalWrite(cameraout, LOW); 
  digitalWrite(valve1out, LOW); 
  digitalWrite(valve2out, HIGH);
  digitalWrite(flowout, HIGH); 
  
  Serial.begin(9600);
}

// the loop routine runs over and over again forever:
void loop() {
  
  
  int valve1val = digitalRead(valve1in);
  int flowval = digitalRead(flowin);
  Serial.println(flowval); 
  Serial.println(valve1val);
  
  // write values for valves  
  
  if (valve1val==HIGH)
    {digitalWrite(valve1out,HIGH);
     digitalWrite(valve2out,LOW);}
  else if(valve1val==LOW)
    {digitalWrite(valve1out,LOW);
     digitalWrite(valve2out,HIGH);}
     
  
     
  // write values for main flow 
  
  if (flowval==HIGH)
    {digitalWrite(flowout,HIGH);}
  else if(flowval==LOW);
    {digitalWrite(flowout,LOW);}
  
   
    
  // trigger IR light and camera  
  digitalWrite(IRout,HIGH);
  digitalWrite(cameraout,HIGH);
  delay(5); //5ms max exposure time (flies beat ~200 Hz)
  
  // reset IR light and camera
  digitalWrite(IRout,LOW);
  digitalWrite(cameraout,LOW);

  // wait 20 ms total (runs at 50Hz)
  delay(15); // 1/f - max exposure time
}

