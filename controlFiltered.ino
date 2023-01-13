#define avg_mult 64.0

const double IN_STRAY_CAP_TO_GND = 24.48; //initially this was 30.00
const double IN_EXTRA_CAP_TO_GND = 0.0;
const double IN_CAP_TO_GND  = IN_STRAY_CAP_TO_GND + IN_EXTRA_CAP_TO_GND;
const int MAX_ADC_VALUE = 1023;

int IN_PIN = A0;
int OUT_PIN = 2;
int PWM_PIN = 9;

int val_ADC;
double voltage;
double capacitance=0.0, capacitance_old=0.1;
double duty;
double pressure[64], pressureF = 0.0;
long counter;
int flag = 0;
double initial = 0.0;

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

  // this should not be necessary, try w/o it later

  pinMode(OUT_PIN, OUTPUT);
  pinMode(IN_PIN, OUTPUT);
  pinMode(PWM_PIN, OUTPUT);  

//  for(int i = 0; i < 100; i++)
//  {
//    readValADC();
//    initial += 2.46 * capacitance;
//  }
//  initial /= 100.0;
  
  timer1Setup();
}

void loop()
{
   
}

double d(double x, double x_old)
{
  return (x - x_old) / 0.1;
}


void readValADC()
{

  //flush old val_ADC value

  val_ADC = 0;

  // read and sum up the values of each cell of the 
  // matrix k times to have the average value
  for (int k = 0; k < avg_mult; k++)
  {
    pinMode(IN_PIN, INPUT);
    digitalWrite(OUT_PIN, HIGH);
    val_ADC += analogRead(IN_PIN);
    //Clear everything for next measurement
    digitalWrite(OUT_PIN, LOW);
    pinMode(IN_PIN, OUTPUT); 
  }

  // divide the integral with k, to have the average value
  val_ADC /= avg_mult;
  voltage = val_ADC * 5.0 / 1024.0;
  capacitance = (double)val_ADC * IN_CAP_TO_GND / (double)(MAX_ADC_VALUE - val_ADC) - 16.31;
//if(capacitance < 0) capacitance = 0;
  for (int k = 63; k > 0; k--)
  {
    pressure[k] = pressure[k-1];
  }
  pressure[0] = 2.46 * capacitance - 7.85 - 0.7 - 1.0;
  pressureF = 0.0;
  for (int k = 0; k < avg_mult; k++)
  {
    pressureF += pressure[k];
  }
  pressureF /= avg_mult;


  Serial.print(duty);
  Serial.print(",");
  Serial.print(capacitance,2);
  Serial.print(",");
  Serial.println(pressureF, 2);
  capacitance_old = capacitance;

}

ISR(TIMER1_COMPA_vect){
   readValADC();
   if(pressureF < 1.0) duty = 1.0;
   if(pressureF > 2.8) duty = 0.0;
   
   analogWrite(PWM_PIN, duty * 255);
}
