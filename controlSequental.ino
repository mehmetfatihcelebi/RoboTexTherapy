#define avg_mult 64.0

const double IN_STRAY_CAP_TO_GND = 24.48; //initially this was 30.00
const double IN_EXTRA_CAP_TO_GND = 0.0;
const double IN_CAP_TO_GND  = IN_STRAY_CAP_TO_GND + IN_EXTRA_CAP_TO_GND;
const int MAX_ADC_VALUE = 1023;

//arduino uno pins
int IN_PIN[3] = {A0, A1, A2}; //{A3, A4, A5} for Lilypad 3 actuator application
int OUT_PIN[3] = {2, 7, 4}; // {A2, 11, 10} for Lilypad 3 actuator application
int PWM_PIN[3] = {9, 10, 11}; // {9, 3, 2} for Lilypad 3 actuator application
int GND_PIN[3] = {3, 5, 6}; // all grounded to - pin for Lilypad 3 actuator application


int val_ADC[3];
double voltage[3];
double capacitance[3];
double duty[3] = {1.0, 0.0, 0.0};
double pressure[3][64], pressureF[3];
//these parameters vary for each sensor sample
double capOffset[3] = {15.0, 15.6, 10.36};
double pressOffset[3] = {9.55, 9.55, 9.55};
double cap2press[3] = {2.46, 2.46, 1.0}; 
long counter;
int flag = 0;
double initial = 0.0;

unsigned long myTime;
unsigned long millisCounter=0;
unsigned long startTime;

void timer1Setup()
{
  // TIMER 1 for interrupt frequency 10 Hz:
  cli(); // stop interrupts
  TCCR1A = 0; // set entire TCCR1A register to 0
  TCCR1B = 0; // same for TCCR1B
  TCNT1  = 0; // initialize counter value to 0
  // set compare match register for 10 Hz increments
  OCR1A = 24999; // = 16000000 / (64 * 10) - 1 (must be <65536)
  // turn on CTC mode
  TCCR1B |= (1 << WGM12);
  // Set CS12, CS11 and CS10 bits for 64 prescaler
  TCCR1B |= (0 << CS12) | (1 << CS11) | (1 << CS10);
  // enable timer compare interrupt
  TIMSK1 |= (1 << OCIE1A);
  sei(); // allow interrupts
}

void setup() 
{
  Serial.begin(9600);

  pinMode(OUT_PIN[0], OUTPUT);
  pinMode(IN_PIN[0], OUTPUT);
  pinMode(PWM_PIN[0], OUTPUT); 
  pinMode(GND_PIN[0], OUTPUT);   
  
  pinMode(OUT_PIN[1], OUTPUT);
  pinMode(IN_PIN[1], OUTPUT);
  pinMode(PWM_PIN[1], OUTPUT); 
  pinMode(GND_PIN[1], OUTPUT);   
  
  pinMode(OUT_PIN[2], OUTPUT);
  pinMode(IN_PIN[2], OUTPUT);
  pinMode(PWM_PIN[2], OUTPUT); 
  pinMode(GND_PIN[2], OUTPUT);   

  digitalWrite(GND_PIN[0], LOW);
  digitalWrite(GND_PIN[1], LOW);
  digitalWrite(GND_PIN[2], LOW);
  
  timer1Setup();
  
  startTime = millis();
}

void loop()
{
   
}

void readValADC(int s)
{

  //flush old val_ADC value

  val_ADC[s] = 0;

  // read and sum up the values of each cell of the 
  // matrix k times to have the average value
  for (int k = 0; k < avg_mult; k++)
  {
    pinMode(IN_PIN[s], INPUT);
    digitalWrite(OUT_PIN[s], HIGH);
    val_ADC[s] += analogRead(IN_PIN[s]);
    //Clear everything for next measurement
    digitalWrite(OUT_PIN[s], LOW);
    pinMode(IN_PIN[s], OUTPUT); 
  }

  // divide the integral with k, to have the average value
  val_ADC[s] /= avg_mult;
  voltage[s] = val_ADC[s] * 5.0 / 1024.0;
  capacitance[s] = (double)val_ADC[s] * IN_CAP_TO_GND / (double)(MAX_ADC_VALUE - val_ADC[s]) - capOffset[s];
//if(capacitance < 0) capacitance = 0;
  for (int k = 63; k > 0; k--)
  {
    pressure[s][k] = pressure[s][k-1];
  }
  pressure[s][0] = cap2press[s] * capacitance[s] - pressOffset[3];
  pressureF[s] = 0.0;
  for (int k = 0; k < avg_mult; k++)
  {
    pressureF[s] += pressure[s][k];
  }
  pressureF[s] /= avg_mult;

  if(s == 2) pressureF[s] -= 17.0;
  

  Serial.print(s);
  Serial.print(",");
  Serial.print(duty[s]);
  Serial.print(",");
  Serial.print(capacitance[s],2);
  Serial.print(",");
  Serial.println(pressureF[s], 2);

  analogWrite(PWM_PIN[s], duty[s] * 255);

}

ISR(TIMER1_COMPA_vect){
   
   readValADC(0);
   readValADC(1);
   readValADC(2);

   myTime = millis();
   if(myTime - startTime >= 30000) {
    flag++;
    startTime = millis();
   }
   if(flag == 3) flag = 0;
  
   
   if(flag == 0)
   {
    duty[0] = 1.0;
    duty[1] = 0.0;
    duty[2] = 0.0;
   }
   else if(flag == 1)
   {
    duty[0] = 0.0;
    duty[1] = 1.0;
    duty[2] = 0.0;
   }
   else if(flag == 2)
   {
    duty[0] = 0.0;
    duty[1] = 0.0;
    duty[2] = 1.0;
   }
   
}
