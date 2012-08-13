/*******************************************************************************
  This program accompanies Arduino distance detect code.  Processing reads
  serial data from the arduino while the scanner is scanning.  Once the scan
  is complete, this program parses the data and creates and array of 3D points.
  The program then creates a 3D model of the 3D points.
  
  Written by Dan Breczins on 12/1/2011

*******************************************************************************/


import processing.serial.*;
import processing.opengl.*;

Serial myPort;

String BUFFER_STRING = "";
int VERTICAL_DEGREE_MIN = 90;
int VERTICAL_DEGREE_MAX = 100;
int VERTICAL_DEGREE_INCREMENT = 5;
int NUMBER_OF_POINTS = 0;
int COUNT = 0;
//int SPHERE_SIZE = 4;

boolean START = true;
float[] positions = new float[100000];
float MY_SCALE = 1;
float DISTANCE_THRESHOLD = 10;

int count = 0;

void setup() {
  size(500, 500, P3D);
  background(0);
  smooth();
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
}

void draw() {
  if(START)
  {
    getData();
    parseData();
    START = false;
  }
  
  //rotation code used from 3D example code included with processing IDE
  background(0);
  lights();
  translate(width / 2, height / 2);
  rotateY(map(mouseX, 0, width, 0, PI));
  rotateZ(map(mouseY, 0, height, 0, -PI));
  noStroke();
  fill(255, 255, 255);
  translate(0, -40, 0);
  drawModel();
  
}


/*******************************************************************************
          GET DATA
*******************************************************************************/
void getData()
{
  String inBuffer;
  while(true)
  {
    count++;
    if(count%1000 == 0)
    {
      if(match(BUFFER_STRING, "-3")!=null)
      {
        return;
      }
    }
    if (myPort.available() > 0) {
      inBuffer = myPort.readString();
      if (inBuffer != null) {
        BUFFER_STRING += inBuffer;
        //println(inBuffer); for debugging
      }
    }
  }
}

/*******************************************************************************
          PARSE DATA
*******************************************************************************/
void parseData()
{
  int startOfData = BUFFER_STRING.indexOf("-1")+2;
  int endOfData = BUFFER_STRING.indexOf("-3");
  int placeHolder = startOfData;
  int positionsPlace = 0;
  float x, y, z, distance, horizontalDegree;
  
  String slicedString = BUFFER_STRING.substring(startOfData, endOfData);
  
  for(int verticalDegree = VERTICAL_DEGREE_MIN; 
      verticalDegree <= VERTICAL_DEGREE_MAX;
      verticalDegree += VERTICAL_DEGREE_INCREMENT)
  {  
    String scanDataString = BUFFER_STRING.substring(placeHolder, 
                            BUFFER_STRING.indexOf("-2",placeHolder));
    String[] scanDataArray = splitTokens(scanDataString, "\n");
    float horizontalDegreeIncrement = 360.0/(float)scanDataArray.length;
    for(int i = 0; i < scanDataArray.length; i++)
    {
      horizontalDegree = i*horizontalDegreeIncrement;
      distance = float(scanDataArray[i]);
      //println(distance); //for debuggin
      if(distance > DISTANCE_THRESHOLD){               
        float adjustVerticalDegree = verticalDegree - 90;        
        x = (distance * cos(radians(adjustVerticalDegree))) 
            * cos(radians(horizontalDegree));
        y = distance * sin(radians(adjustVerticalDegree));
        z = (distance * cos(radians(adjustVerticalDegree)))
            * sin(radians(horizontalDegree));  
        positions[positionsPlace] = x;
        positions[positionsPlace+1] = y;
        positions[positionsPlace+2] = z;
        positionsPlace += 3; 
        NUMBER_OF_POINTS += 3;
      }
    }
    placeHolder = BUFFER_STRING.indexOf("-2", placeHolder)+2;
  }
}

/*******************************************************************************
          BUILD MODEL
*******************************************************************************/
void drawModel()
{
  //translate(width/2, height/2, 0);
  stroke(255);
  fill(255);
  lights();
  for(int i = 0; i < NUMBER_OF_POINTS; i+=3)
  {
    translate(positions[i]*MY_SCALE, positions[i+1]*MY_SCALE, 
              positions[i+2]*MY_SCALE);
    stroke(255,120);
    fill(255, 40);
    ellipse(0, 0, 5, 5);
    translate(-positions[i]*MY_SCALE, -positions[i+1]*MY_SCALE,
              -positions[i+2]*MY_SCALE);
  }
}

//useful for debugging
void printPositions()
{
  for(int i = 0; i < NUMBER_OF_POINTS; i+=3)
  {
    for(int j = 0; j < 3; j++)
    {
      if(j==0)
      {
        println("x = " + positions[i] + "\n");
      }
      else if(j==1)
      {
        println("y = " + positions[i+j] + "\n");
      }
      else
      {
        println("z = " + positions[i+j] + "\n");
      }
    }
    println("\n");
  }
}
