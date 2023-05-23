#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

// g++ -o fpga_controller_test fpga_controller_test.cpp -lpigpio -lrt -lpthread
// sudo ./fpga_controller_test

// GPIO pin number
const int sram_select_0 = 24; //GPIO 0 is physical pin 11
const int sram_select_1 = 23;
const int inst_valid = 17;
const int fpga_idle = 27;
const int fpga_execute= 22;

//instruction
const uint8_t fpga_write_inst = 2;
const uint8_t fpga_read_inst = 3;

// sram addresses for current image, background image, and result image
const uint24_t result_img_address = 0;
const uint24_t current_img_address = 16385;
const uint24_t background_img_address = 65538;

// Function to write char to the SRAM chip.
void writeData(int handle, int address, std::vector<char> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

// Function to read char from the SRAM chip.
std::vector<char> readData(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<char>(buffer.begin() + 4, buffer.end());
}

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

    // Open SPI channel
    int handle = spiOpen(CHANNEL, SPEED, 0);

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

    // Declaring Mat images
    cv::Mat img;
    cv::Mat resized_img;
    std::vector<uchar> img_vector;

    // Load the image
    img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing data onto sram
    writeChar(handle, result_img_address, img_vector);

    // initial setup
    // setup 00 case
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 0);

    // Load the image
    // TODO: change the image path
    img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing data onto sram
    writeData(handle, result_img_address, img_vector);

    // setup 01 case
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 0);

    // Load the image
    // TODO: change the image path
    img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing data onto sram
    writeData(handle, result_img_address, img_vector);

    // setup 10 case
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 1);
    
    // Load the image
    // TODO: change the image path
    img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    resized_img;
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing data onto sram
    writeData(handle, result_img_address, img_vector);

    // setup 11 case <-- no need for the last case?
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 1);

    //bool test_switch = 0;

    // Variables for results
    std::vector<uchar> result_vector;
    cv::Mat restored_img;

    int index = 0;
    std::string directory_path = "/home/pi/Desktop/";
    std::string img_path = directory_path + "";
    std::string result_img_path = directory_path + "";
    // main loop
    while (1)
    {
        //gpioWrite(fpga_execute, 1);

        //setup current case
        // Load the image
        // TODO: change the image path
        img = cv::imread("path_to_your_image.jpg", cv::IMREAD_COLOR);

        // Check if the image is loaded successfully
        if(img.empty())
        {
            std::cout << "Could not read the image." << std::endl;
            return 1;
        }
        
        // Resize the image to 128x128
        resized_img;
        cv::resize(img, resized_img, cv::Size(128, 128));

        // Convert the resized image to a single vector
        img_vector.assign(resized_img.datastart, resized_img.dataend);

        // Writing data onto sram
        writeData(handle, result_img_address, img_vector);

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
        result_vector = readData(handle, result_img_address, img_vector.size());
        restored_img(128, 128, CV_8UC3, result_vector.data());

        // Save the restored image
        cv::imwrite("/home/your_username/images/restored_image.jpg", restored_img);
    }

    // Terminate pigpio library
    gpioTerminate();

    return 0;
}

/*
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