/*******************************************************************************
  This program uses an arduino uno, max-sonar distance detectar, continuous
  rotation servo and non-continuous rotation servo to create an aproximate
  3D scan of a room.
  
  Written by Dan Breczins on 12/1/2011

*******************************************************************************/

#include <Servo.h>

#define HORIZONTAL_SERVO_PIN            9
#define VERTICAL_SERVO_PIN              6
#define ANALOG_SWITCH_PIN               3
#define DIGITAL_DISTANCE_PIN            3

#define ANALOG_DISTANCE_DETECT_PIN      0

//if using analog distance detect, the number of scans to perform and 
//average
#define NUMBER_OF_SCANS                 30

#define HORIZONTAL_SERVO_COUNTER_SPEED  85

//96 is slowest (most detailed scan speed) higer values are faster/less 
//detailed
#define HORIZONTAL_SERVO_CLOCK_SPEED    96  

//value to write to continuous rotation servo to get it to "stop"
#define HORIZONTAL_SERVO_STOP           90

//time in microseconds to advance servo between scans
#define HORIZONTAL_SERVO_FORWARD_TIME   300 

//these can be adjust from about 30 - 170
#define VERTICAL_SCAN_MIN               90  
#define VERTICAL_SCAN_MAX               100

//adjusts the number of vertical degrees between scans
#define VERTICAL_DEGREE_INCREMENT       5   

//sample size for analog scans
#define NUMBER_OF_SCANS                 10 

//time to move horizontal servo forward after rewind() function
#define RESTART_OFFSET_TIME             200 

Servo horizontalServo;
Servo verticalServo;

int VERTICAL_SERVO_POSITION;

boolean rotatingClockwise = true;
boolean scanComplete = false;
float sum;
long analogVolt, cm;
long duration, inches;

void setup()
{
  pinMode(ANALOG_DISTANCE_DETECT_PIN, INPUT);
  horizontalServo.attach(HORIZONTAL_SERVO_PIN);
  verticalServo.attach(VERTICAL_SERVO_PIN);
  Serial.begin(9600);  
}

void loop()
{
  while(!scanComplete)
  {
    performScan();
  }
}

/*******************************************************************************
          PERFORM SCAN
*******************************************************************************/
void performScan()
{
  initialise();
  while(VERTICAL_SERVO_POSITION <= VERTICAL_SCAN_MAX)
  {
    while(analogRead(ANALOG_SWITCH_PIN)<1000)
    {
      horizontalServo.write(HORIZONTAL_SERVO_STOP);
      delay(100);
      Serial.print(distanceRead());
      Serial.print("\n");
      horizontalServo.write(HORIZONTAL_SERVO_CLOCK_SPEED);
      delay(HORIZONTAL_SERVO_FORWARD_TIME);
    }
    
    horizontalServo.write(HORIZONTAL_SERVO_COUNTER_SPEED);
    delay(100);
    Serial.print("-2\n");
    nextScan();
  }
  Serial.print("-3\n");
  rewind();
  scanComplete = true;
}

/*******************************************************************************
          INITIALISE
*******************************************************************************/
void initialise()
{
  rewind();
  VERTICAL_SERVO_POSITION = VERTICAL_SCAN_MIN;
  verticalServo.write(VERTICAL_SERVO_POSITION);
  delay(100);
  Serial.print("-1\n");
  delay(1000);
}

/*******************************************************************************
          REWIND
*******************************************************************************/
void rewind()
{
  horizontalServo.write(HORIZONTAL_SERVO_COUNTER_SPEED);
  delay(100);  
  while(analogRead(ANALOG_SWITCH_PIN)<1000)
  {
    horizontalServo.write(HORIZONTAL_SERVO_COUNTER_SPEED);
  }  
  horizontalServo.write(HORIZONTAL_SERVO_CLOCK_SPEED);
  delay(RESTART_OFFSET_TIME);
  horizontalServo.write(HORIZONTAL_SERVO_STOP);  
}

/*******************************************************************************
          NEXT SCAN
*******************************************************************************/
void nextScan()
{
  rewind();
  VERTICAL_SERVO_POSITION += VERTICAL_DEGREE_INCREMENT;
  verticalServo.write(VERTICAL_SERVO_POSITION);
  delay(100);
}

/*******************************************************************************
          DISTANCE READ
*******************************************************************************/

/* Ping))) Sensor
  
   This sketch reads a PING))) ultrasonic rangefinder and returns the
   distance to the closest object in range. To do this, it sends a pulse
   to the sensor to initiate a reading, then listens for a pulse 
   to return.  The length of the returning pulse is proportional to 
   the distance of the object from the sensor.
     
   The circuit:
	* +V connection of the PING))) attached to +5V
	* GND connection of the PING))) attached to ground
	* SIG connection of the PING))) attached to digital pin 7

   http://www.arduino.cc/en/Tutorial/Ping
   
   created 3 Nov 2008
   by David A. Mellis
   modified 30 Aug 2011
   by Tom Igoe
 
   This example code is in the public domain.
 */
int distanceRead()
{
  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(DIGITAL_DISTANCE_PIN, OUTPUT);
  digitalWrite(DIGITAL_DISTANCE_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(DIGITAL_DISTANCE_PIN, HIGH);
  delayMicroseconds(5);
  digitalWrite(DIGITAL_DISTANCE_PIN, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH
  // pulse whose duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(DIGITAL_DISTANCE_PIN, INPUT);
  duration = pulseIn(DIGITAL_DISTANCE_PIN, HIGH);

  // convert the time into a distance
  //inches = microsecondsToInches(duration);
  cm = microsecondsToCentimeters(duration);
  
  //delay(100);
  
  return cm;
}

long microsecondsToInches(long microseconds)
{
  // According to Parallax's datasheet for the PING))), there are
  // 73.746 microseconds per inch (i.e. sound travels at 1130 feet per
  // second).  This gives the distance travelled by the ping, outbound
  // and return, so we divide by 2 to get the distance of the obstacle.
  // See: http://www.parallax.com/dl/docs/prod/acc/28015-PING-v1.3.pdf
  return microseconds / 74 / 2;
}

long microsecondsToCentimeters(long microseconds)
{
  // The speed of sound is 340 m/s or 29 microseconds per centimeter.
  // The ping travels out and back, so to find the distance of the
  // object we take half of the distance travelled.
  return microseconds / 29 / 2;
}

/*******************************************************************************
          DISTANCE READ (ANALOG)
*******************************************************************************/
//
//int distanceRead()
//{
//  
//  sum = 0;
//  analogVolt = 0;
//  int i;
//  for(i=0; i<NUMBER_OF_SCANS; i++)
//  {
//    analogVolt = analogRead(ANALOG_DISTANCE_DETECT_PIN);
//    sum += analogVolt;
//    //delay 10;???
//  }
//  return (sum/NUMBER_OF_SCANS)*2.54; //returns cm  
//  //delay(100);//may not be necessary?
//}

