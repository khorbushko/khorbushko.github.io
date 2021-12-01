---
layout: post
comments: true
title: "Building a car with Arduino"
categories: article
tags: [arduino, Arduino UNO]
excerpt_separator: <!--more-->
comments_id: 65

author:
- kyryl horbushko
- Lviv
---

Having fun and learning something new - some of the best things that we can do. 

Some time ago, I wrote about [arduino]({% post_url 2021-01-04-hello-arduino %}) and [some basic stuff]({% post_url 2021-04-17-arduino-crash-cource %}) that we can do with various elements and components. Off cause, I didn't cover every component that I played with, but some, that can be used today I did.
<!--more-->

> Another post that u can find interesting - [how to observe serial ports on macOS]({% post_url 2021-05-05-observe-serial-ports-on-macOS %})

My son likes to play with a car (who didn't? ;]). Play and learn - it's a good way to go. So we decided to build a car - "with headlights" and "with auto-pilot" and "with remote control" and "with display" and "with light-sensors" and "with buzzer" and a few more :]. 

## Components and tools

The list of needed **components** are next:

* L298N Motordriver x1
* Ultrasonic Sensor - HC-SR04 x1
* Arduino UNO x1 with USB cable x1
* Sensor shield V5 x1
* 4WD Smart Robot Car Chassis (baseplates) x1
* Wheels x4
* Engines x4
* Servo
* Screws with nuts M3 x18
* Spacers M3x60 x6
* Resistor 220 Ohm x2
* LED lights x2
* Wires (a bunch :) - male-female, male-male, female-female
* Batteries AA x4

> I bought parts from different sets, and without any instruction, so some of them are not perfectly fit ;]. 
> 
> Also I started within the simplest variant - without remote control and any additional sensors, all modifications will be added a bit later.

**Tools:**

* Solder iron
* Screwdriver

**Soft:**

* IDE Arduino/Visual Code
* Fritzing (optional, for schematic)

In total, a minimal set of components is:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/components.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/components.png" alt="components.png" width="550"/>
</a>
</div>
<br>
<br>

## Assembling

> A lot of photos!

Before we actually starts, it's good to see how all components are connected with each other, in other words, it's good to see the schematic:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/scheme.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/scheme.png" alt="scheme.png" width="550"/>
</a>
</div>
<br>
<br>

> This scheme is the simplest one and does not include IR components and BLE modules; We can simplify it even more by removing LEDs

Let's go step-by-step.

The actual assembling I started by soldering wires to the DC motors. This process takes a few sub-steps:

Prepare motor:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor.png" alt="motor.png" width="250"/>
</a>
</div>
<br>
<br>

connect wires:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor_with_wires.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor_with_wires.png" alt="motor_with_wires.png" width="250"/>
</a>
</div>
<br>
<br>

solder wires:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/soldered-wires.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/soldered-wires.png" alt="soldered-wires.png" width="250"/>
</a>
</div>
<br>
<br>

Now, we can start assembling the chassis and connect motors to them.

remove protection from acrylic chassis and holders:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-1.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-1.png" alt="motor-1.png" width="250"/>
</a>
</div>
<br>
<br>

prepare screws and nuts:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/screws.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/screws.png" alt="screws.png" width="250"/>
</a>
</div>
<br>
<br>

put motors on chassis and assemble them:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-assembled-1.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-assembled-1.png" alt="motor-assembled-1.png" width="250"/>
</a>
</div>
<br>
<br>

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-assembled-2.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/motor-assembled-2.png" alt="motor-assembled-2.png" width="250"/>
</a>
</div>
<br>
<br>

Next step - add wheels:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/wheels.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/wheels.png" alt="wheels.png" width="250"/>
</a>
</div>
<br>
<br>

add spacers

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/spacers.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/spacers.png" alt="spacers.png" width="250"/>
</a>
</div>
<br>
<br>

and add top chassis

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/top-chassis.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/top-chassis.png" alt="top-chassis.png" width="250"/>
</a>
</div>
<br>
<br>

Now, it's time to connect DC motors to L298N bridge:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/L28N.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/L28N.png" alt="L28N.png" width="250"/>
</a>
</div>
<br>
<br>

The next step is a bit messy - we should assemble servo. The components that I bought were a bit miss-aligned and can't be assembled easily, so I manually adjust some plastic parts and then assemble the servo with its holder. After we should add an ultrasonic reader to the servo - I used wires to connect them.

The complete result shown on pics below:


<div style="text-align:center">

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-1.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-1.png" alt="servo-1.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-2.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-2.png" alt="servo-2.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-3.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-3.png" alt="servo-3.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-4.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-4.png" alt="servo-4.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-5.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-5.png" alt="servo-5.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-6.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-6.png" alt="servo-6.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-7.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-7.png" alt="servo-7.png" width="250" style="padding:10px"/>
</a>

<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-8.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-8.png" alt="servo-8.png" width="250" style="padding:10px"/>
</a>

</div>
<br>
<br>

After this operations the car looks like this:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-9.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/servo-9.png" alt="servo-9.png" width="450"/>
</a>
</div>
<br>
<br>

The next step is to combine the Arduino board with the sensor shield. I bought [v5]({% link assets/posts/images/2021-12-01-building-a-car-toy/doc/arduino_sensor_shield.pdf %}).

The schematic for this component is next:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/SensorShieldV5xLayout.jpg">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/SensorShieldV5xLayout.jpg" alt="SensorShieldV5xLayout.jpg" width="550"/>
</a>
</div>
<br>
<br>

To use a shield, we should place it on the Arduino board and align it to the right side.

> Make sure that all pins are in their places.

The final wiring looks like this:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/wiring.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/wiring.png" alt="wiring.png" width="650"/>
</a>
</div>
<br>
<br>

The full car photo:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/car.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/photo/car.png" alt="car.png" width="550"/>
</a>
</div>
<br>
<br>

This is a minimal configuration that can be used for a car. Off cause we can use only 2 engines, we can reduce qty of wheels and makes some other modification, but this is another story.

## Programming

To make our car movable, we need to add a few things.

* Need to control engines (DC motors and L298N)
* Use ultrasonic component to detect obstacles (servo and HC-SR04)
* Enable lighting (using LEDs) if obstacles occurs

> I didn't reinvent the wheel, so just grab the code from the Arduino forum and adjust a bit for my needs (unfortunately I lost the link, but u can easily google for it). 

We can go step-by-step.

### Define all pins

We have already assembled the car, some pins are used on an Arduino board to control specific components. It's time to define them in the code.

#### Servo

For `Servo` we must define 3 pins and create an object instance

{% highlight c++ %}
#include <Servo.h>

Servo servo;

const int ultrasonicPin = 13;
const int ultrasonicEchoPin = 12;
const int servoControlPin = 11;
{% endhighlight %}

It's good to know, how servo works - according to doc, we can rotate it from 0 to 180 degrees. This mean, that we can scan for obstacle only "effective" zone - from 60 to 120 degrees. In other words:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/servo_range.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/servo_range.png" alt="servo_range.png" width="350"/>
</a>
</div>
<br>
<br>

so in code, this can be defined as next

{% highlight c++ %}
#define PULSE_PROBE_COUNT 7
#define SERVO_START_POSITION 60
unsigned char scannedAngles[PULSE_PROBE_COUNT] = {
    SERVO_START_POSITION, 70, 80, 90, 100, 110, 120};
{% endhighlight %}

#### Motor

The whole motor pins and related values can be defined as next:

{% highlight c++ %}
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
{% endhighlight %}

#### Other defines

We also need to define pins for LED and store distance info. This can be done like this:

{% highlight c++ %}
unsigned int distances[PULSE_PROBE_COUNT];

// head light LEDs

const int leftDiodePin = 9;
const int rightDiodePin = 10;
{% endhighlight %}


### Initialization

We are ready to configure initial state for all components:

{% highlight c++ %}
void setup()
{
    configureUlstrasonic();
    configureBridge();
    configureServo();
    configureHeadLights();

    testMotors();
    initialScan();
}
{% endhighlight %}

In details:

{% highlight c++ %}
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
{% endhighlight %}


> `readDistance` will be defined below

### Loop

After everything is done and ready, we can define the main loop - scan surrounding space and move forward if space is free or backward and to some side if not.

To do so, we need to read data from an ultrasonic sensor in effective range, analyze it, and control or engines:

{% highlight c++ %}

// MOVEMENT

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

// SCAN

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
// and recording the distance observed. This takes a reading, then
// sends the servo to the next angle. Call repeatedly once every 50 ms or so.
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
{% endhighlight %}

> As I mention above, I didn't reinvent the wheel and just grab this code from an unknown author on the Arduino forum.

That's it. We are ready to go.

<details><summary> The full code here </summary>
<p>

{% highlight c++ %}
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
// and recording the distance observed. This takes a reading, then
// sends the servo to the next angle. Call repeatedly once every 50 ms or so.
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

{% endhighlight %}

</p>
</details>
<br>

## Demo

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/demo_big.gif">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-01-building-a-car-toy/demo.gif" alt="demo" width="450"/>
</a>
</div>
<br>
<br>


[download sources]({% link assets/posts/images/2021-12-01-building-a-car-toy/doc/car.zip %})

## Resources

* [`Servo`](https://www.arduino.cc/reference/en/libraries/servo/)
* [`Ultrasonic sensor`](https://www.tutorialspoint.com/arduino/arduino_ultrasonic_sensor.htm)
* [L298N](https://create.arduino.cc/projecthub/ryanchan/how-to-use-the-l298n-motor-driver-b124c5)
* [Servo-motors](https://www.instructables.com/Arduino-Servo-Motors/)
* [Sensor shield v5](https://forum.arduino.cc/t/arduino-sensor-shield-v5-apc220-manual/223457/2)