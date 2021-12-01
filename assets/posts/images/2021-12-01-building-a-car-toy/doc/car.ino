#include <Servo.h>

Servo servo;

// Servo

const int ultrasonicPin = 13;
const int ultrasonicEchoPin = 12;
const int servoControlPin = 11;

// L298N H bridge

enum MotorDirection
{
    LEFT,
    RIGHT
};

const int leftMotorPWMPin = 6;
const int in1Pin = 7;
const int in2Pin = 5;
const int in3Pin = 4;
const int in4Pin = 2;
const int rightMotorPWMPin = 3;

// Ultrasonic

#define PULSE_PROBE_COUNT 7
#define SERVO_START_POSITION 60
unsigned char scannedAngles[PULSE_PROBE_COUNT] = {
    SERVO_START_POSITION, 70, 80, 90, 100, 110, 120};
unsigned int distances[PULSE_PROBE_COUNT];

// head light LEDs

const int leftDiodePin = 9;
const int rightDiodePin = 10;

void setup()
{
    configureUlstrasonic();
    configureBridge();
    configureServo();
    configureHeadLights();

    testMotors();
    initialScan();
}

void loop()
{
    readNextDistance();
    analyzeDataAndProceed();

    delay(50);
}

void analyzeDataAndProceed()
{
    unsigned char tooClose = 0;
    for (unsigned char i = 0; i < PULSE_PROBE_COUNT; i++)
        if (distances[i] < 300)
            tooClose = 1;
    if (tooClose)
    {
        moveTo(LEFT, -180);
        moveTo(RIGHT, -80);
        digitalWrite(leftDiodePin, HIGH);
        digitalWrite(rightDiodePin, HIGH);
    }
    else
    {
        moveTo(LEFT, 255);
        moveTo(RIGHT, 255);
        digitalWrite(leftDiodePin, LOW);
        digitalWrite(rightDiodePin, LOW);
    }
}

// CONFIG

void configureUlstrasonic()
{
    pinMode(ultrasonicPin, OUTPUT);
    pinMode(ultrasonicEchoPin, INPUT);
    digitalWrite(ultrasonicPin, LOW);
}

void configureBridge()
{
    pinMode(leftMotorPWMPin, OUTPUT);
    pinMode(in1Pin, OUTPUT);
    pinMode(in2Pin, OUTPUT);
    pinMode(in3Pin, OUTPUT);
    pinMode(in4Pin, OUTPUT);
    pinMode(rightMotorPWMPin, OUTPUT);
}

void configureHeadLights()
{
    pinMode(leftDiodePin, OUTPUT);
    pinMode(rightDiodePin, OUTPUT);
}

void configureServo()
{
    servo.attach(servoControlPin);
    servo.write(SERVO_START_POSITION);
}

void initialScan()
{
    delay(200);
    for (unsigned char i = 0; i < PULSE_PROBE_COUNT; i++)
        readNextDistance(),
            delay(200);

    servo.write(SERVO_START_POSITION);
}

// CONTROL

// Set motor speed: 255 full ahead, −255 full reverse, 0 stop
void moveTo(enum MotorDirection m, int speed)
{
    digitalWrite(
        m == LEFT ? in1Pin : in3Pin,
        speed > 0 ? HIGH : LOW);
    digitalWrite(
        m == LEFT ? in2Pin : in4Pin,
        speed <= 0 ? HIGH : LOW);
    analogWrite(
        m == LEFT ? leftMotorPWMPin : rightMotorPWMPin,
        speed < 0 ? -speed : speed);
}

void testMotors()
{
    static int speed[8] = {
        128, 255, 128, 0,
        -128, -255, -128, 0};
    moveTo(RIGHT, 0);
    for (unsigned char i = 0; i < 8; i++)
        moveTo(LEFT, speed[i]), delay(200);

    for (unsigned char i = 0; i < 8; i++)
        moveTo(RIGHT, speed[i]), delay(200);
}

// Read distance from the ultrasonic sensor, return distance in mm
// Speed of sound in dry air, 20C is 343 m/s
// pulseIn returns time in microseconds (10ˆ−6)
// 2d=p*10ˆ−6s*343m/s=p*0.00343m=p*0.343mm/us
unsigned int readDistance()
{
    digitalWrite(ultrasonicPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(ultrasonicPin, LOW);
    unsigned long period = pulseIn(ultrasonicEchoPin, HIGH);
    return period * 343 / 2000;
}

// Scan the area ahead by sweeping the ultrasonic sensor left and right
// and recording the distance observed . This takes a reading , then
// sends the servo to the next angle . Call repeatedly once every 50 ms or so .
void readNextDistance()
{
    static unsigned char angleIndex = 0;
    static signed char step = 1;
    distances[angleIndex] = readDistance();
    angleIndex += step;
    if (angleIndex == PULSE_PROBE_COUNT - 1)
        step = -1;
    else if (angleIndex == 0)
        step = 1;
    servo.write(scannedAngles[angleIndex]);
}
