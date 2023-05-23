#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <vector>

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
const uint8_t fpga_write_inst = 2;
const uint8_t fpga_read_inst = 3;

// sram addresses for current image, background image, and result image
// TODO: change the addresses
const uint24_t result_img_address = 1;
const uint24_t current_img_address = 2;
const uint24_t background_img_address = 3;

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

/*
#include <opencv2/opencv.hpp>

int main() {
    // Load the image
    cv::Mat img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }

    // Resize the image to 128x128
    cv::Mat resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Save the resized image
    cv::imwrite("resized_image.jpg", resized_img);

    return 0;
}


#include <opencv2/opencv.hpp>
#include <vector>

int main() {
    // Load the image
    cv::Mat img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }

    // Resize the image to 128x128
    cv::Mat resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    std::vector<uchar> img_vector;
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // img_vector now contains the flattened image

    return 0;
}
*/