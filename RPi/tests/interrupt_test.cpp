#include <iostream>
#include <pigpio.h>

// GPIO pin number
const int buttonPin = 17; // GPIO 17 is Pin 11

//g++ -o interrupt_test interrupt_test.cpp -lpigpio -lrt -lpthread
//sudo ./interrupt_test

// This function will be called every time an event on the button pin is triggered by the interrupt
void buttonPress(int gpio, int level, uint32_t tick)
{
    if (level == 0) // Level 0 means a falling edge was detected
    {
        std::cout << "Button Pressed!" << std::endl;
    }
}

int main()
{
    // Initialise pigpio library
    if (gpioInitialise() < 0)
    {
        std::cout << "pigpio initialisation failed." << std::endl;
        return 1;
    }

    // Set the pin as input
    gpioSetMode(buttonPin, PI_INPUT);

    // Enable pull-up resistor
    gpioSetPullUpDown(buttonPin, PI_PUD_UP);

    // Setup the interrupt function to run when the button is pressed.
    // It will run in a different thread
    if (gpioSetAlertFunc(buttonPin, buttonPress) < 0)
    {
        std::cout << "Unable to setup alert function." << std::endl;
        return 1;
    }

    // main loop
    while (1)
    {
        time_sleep(1); // delay for 1 second
    }

    // Terminate pigpio library
    gpioTerminate();

    return 0;
}