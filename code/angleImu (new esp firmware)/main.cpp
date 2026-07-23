#include "HardwareSerial.h"
#include "esp32-hal.h"
#include <Arduino.h>
#include <Adafruit_LSM6DSO32.h>
#include <Adafruit_LSM6DS.h>
#include <Wire.h>
#include <cmath>
#include <math.h>
//#include <Wire.h>
Adafruit_LSM6DSO32 dso32;
unsigned long timeRef = 0; //may tehila burn extra long on the cross for using global variables
float Xi = 1, Yi = 1, Zi = 1;
float azimuth, elevation, norm;


int normalize(float, float, float);

void setup() {
  Wire.setPins(4, 5);
  Wire.begin();
  Serial.begin(115200);
  //Wire.begin();
  while (!Serial) delay(10); //disgusting, but they used delay in adafruits ref code
  if(!dso32.begin_I2C(0x6A)) {  //0x6A is the adress for the adafruit imu

    while (1) {
      delay(10);
      Serial.println("connection failure: lsm6dso32");
    }
  }
  Serial.println("connection established: lsm6dso32");
  dso32.setAccelRange(LSM6DSO32_ACCEL_RANGE_8_G);
  dso32.setGyroRange(LSM6DS_GYRO_RANGE_500_DPS);
  dso32.setAccelDataRate(LSM6DS_RATE_104_HZ);
  dso32.setGyroDataRate(LSM6DS_RATE_104_HZ);
  Serial.println("configuration complete: lsm6dso32 ranges");

  
}

void loop() {
  
  // put your main code here, to run repeatedly:
  sensors_event_t accel, gyro, temp; //no idea what temp does
  dso32.getEvent(&accel, &gyro, &temp);
  Xi = 0.05 * accel.acceleration.x + 0.95 * Xi;
  Yi = 0.05 * accel.acceleration.y + 0.95 * Yi;
  Zi = 0.05 * accel.acceleration.z + 0.95 * Zi;

  if (millis() - timeRef >= 1000) {
    timeRef = millis();
    normalize(Xi, Yi, Zi);
  }

}

// it assumes gravitational pull is along the x axis and that is frame 0, and that the frame of the imu is frame 1.
int normalize(float x, float y, float z) {
  norm = sqrt(x*x + y*y + z*z);
  x = x/norm;
  y = y/norm;
  z = z/norm;
  azimuth = atan2(y, x) * (180.0 / M_PI);
  elevation = atan2(-z, sqrt(x*x + y*y)) * (180.0 / M_PI);
  Serial.printf("angle azimuth: %.2f elevation: %.2f\n", azimuth, elevation);

}