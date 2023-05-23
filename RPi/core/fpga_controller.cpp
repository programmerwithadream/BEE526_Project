#include <iostream>
#include <pigpio.h>

// g++ -o fpga_controller fpga_controller.cpp -lpigpio -lrt -lpthread
// sudo ./fpga_controller

// GPIO pin number
// TODO: ENTER THE RIGHT GPIO PIN NUMBERS
const int sram_select_0 = 24; //GPIO 0 is physical pin 11
const int sram_select_1 = 23;
const int inst_valid = 17;
const int fpga_idle = 27;
const int fpga_execute= 22;

//instruction
const int fpga_inst = 0;

// sram addresses for current image, background image, and result image
// TODO: change the addresses
const int result_img_address = 1;
const int current_img_address = 2;
const int background_img_address = 3;

// This function will be called every time fpga stops being idle
// to ensure fpga_execute pins returns low
void notIdle(int gpio, int level, uint32_t tick)
{
    gpioWrite(fpga_execute, 0);
}

int main()
{
    // Initialise pigpio library
    if (gpioInitialise() < 0)
    {
        std::cout << "pigpio initialisation failed." << std::endl;
        return 1;
    }

    // Set the pins
    gpioSetMode(sram_select_0, PI_OUTPUT);
    gpioSetMode(sram_select_1, PI_OUTPUT);
    gpioSetMode(inst_valid, PI_INPUT);
    gpioSetMode(fpga_idle, PI_INPUT);
    gpioSetMode(fpga_execute, PI_OUTPUT);

    // Enable pull-up resistor
    gpioSetPullUpDown(inst_valid, PI_PUD_UP);
    gpioSetPullUpDown(fpga_idle, PI_PUD_UP);

    // Setup the interrupt function to run when the button is pressed.
    // It will run in a different thread
    if (gpioSetAlertFunc(fpga_idle, notIdle) < 0)
    {
        std::cout << "Unable to setup alert function." << std::endl;
        return 1;
    }

    // initial setup
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 0);
    // setup 00 case
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 0);
    // setup 01 case
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 1);
    // setup 10 case
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 1);
    // setup 11 case <-- no need for the last case?

    // main loop
    while (1)
    {
        gpioWrite(fpga_execute, 1);

        //setup current case

        //wait till fpga is done

        if (sram_select_0 == 0 && sram_select_1 == 0) {
            gpioWrite(sram_select_0, 1);
            gpioWrite(sram_select_1, 0);
        } else if (sram_select_0 == 1 && sram_select_1 == 0) {
            gpioWrite(sram_select_0, 0);
            gpioWrite(sram_select_1, 1);
        } else if (sram_select_0 == 0 && sram_select_1 == 1) {
            gpioWrite(sram_select_0, 1);
            gpioWrite(sram_select_1, 1);
        } else {
            gpioWrite(sram_select_0, 0);
            gpioWrite(sram_select_1, 0);
        }
        
        //read results

    }

    // Terminate pigpio library
    gpioTerminate();

    return 0;
}