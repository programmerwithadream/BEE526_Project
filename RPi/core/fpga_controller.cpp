#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

#define CHANNEL_0 0
#define CHANNEL_1 1
#define SPEED 5000000
#define READ 0x03
#define WRITE 0x02

// g++ -o fpga_controller_test fpga_controller_test.cpp `pkg-config --cflags --libs opencv` -lpigpio -lrt -lpthread
// sudo ./fpga_controller_test

// GPIO pin number
const int sram_select_0 = 24; //GPIO 0 is physical pin 11
const int sram_select_1 = 23;
const int inst_valid = 17;
const int fpga_idle = 27;
const int fpga_execute= 22;

// sram addresses for current image, background image, and result image
const int result_img_address = 0;
const int current_img_address = 16385;
const int background_img_address = 65538;

bool fpga_working = 0;

// Function to write uchar to the SRAM chip.
void writeData(int handle, int address, std::vector<uchar> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

// Function to read uchar from the SRAM chip.
std::vector<uchar> readData(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<uchar>(buffer.begin() + 4, buffer.end());
}

// This function will be called every time fpga stops being idle
// to ensure fpga_execute pins returns low
void notIdle(int gpio, int level, uint32_t tick)
{
    if (level == 0) {
        gpioWrite(fpga_execute, 0);
        fpga_working = 1;
    }
    
    std::cout << "FPGA executing..." << std::endl;
}

void load_background_subtraction_inst(int handle) {
    uint32_t uint_result_img_address = (uint32_t) result_img_address;
    uint32_t uint_current_img_address = (uint32_t) current_img_address;
    uint32_t uint_background_img_address = (uint32_t) background_img_address;
    std::vector<char> buffer = {0xFF, (char)((uint_result_img_address>>16)&0xFF), (char)((uint_result_img_address>>9)&0xFF), (char)((uint_result_img_address)&0xFF), (char)((uint_current_img_address>>16)&0xFF), (char)((uint_current_img_address>>8)&0xFF), (char)((uint_current_img_address)&0xFF), (char)((uint_background_img_address>>16)&0xFF), (char)((uint_background_img_address>>8)&0xFF), (char)((uint_background_img_address)&0xFF)};

    spiWrite(handle, &buffer[0], 10);
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
    int handle_0 = spiOpen(CHANNEL_0, SPEED, 0);
    int handle_1 = spiOpen(CHANNEL_1, SPEED, 0);

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

    int inst_valid_counter = 0;
    while (!gpioRead(inst_valid)) {
        load_background_subtraction_inst(handle_1);
        
        if(inst_valid_counter > 10) {
            std::cout << "unable to load instruction onto FPGA." << std::endl;
            return 1;
        }
        inst_valid_counter++;
    }

    // Declaring Mat images
    cv::Mat img;
    cv::Mat resized_img;
    cv::Mat resized_background_img;
    std::vector<uchar> img_vector;

    // initial setup
    // setup 00 case
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 0);

    // Load the image
    img = cv::imread("/home/pi/Desktop/test_images/PETS2006/input/in000000.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    cv::resize(img, resized_img, cv::Size(128, 128));
    cv::resize(img, resized_background_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing current image onto sram
    writeData(handle_0, current_img_address, img_vector);

    // Converting background img to a single vector
    img_vector.assign(resized_background_img.datastart, resized_background_img.dataend);

    // Writing background image onto sram
    writeData(handle_0, background_img_address, img_vector);

    // setup 01 case
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 0);

    // Load the image
    img = cv::imread("/home/pi/Desktop/test_images/PETS2006/input/in000001.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing current image onto sram
    writeData(handle_0, current_img_address, img_vector);

    // Converting background img to a single vector
    img_vector.assign(resized_background_img.datastart, resized_background_img.dataend);

    // Writing background image onto sram
    writeData(handle_0, background_img_address, img_vector);

    // setup 10 case
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 1);
    
    // Load the image
    img = cv::imread("/home/pi/Desktop/test_images/PETS2006/input/in000002.jpg", cv::IMREAD_COLOR);

    // Check if the image is loaded successfully
    if(img.empty())
    {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }
    
    // Resize the image to 128x128
    cv::resize(img, resized_img, cv::Size(128, 128));

    // Convert the resized image to a single vector
    img_vector.assign(resized_img.datastart, resized_img.dataend);

    // Writing current image onto sram
    writeData(handle_0, current_img_address, img_vector);

    // Converting background img to a single vector
    img_vector.assign(resized_background_img.datastart, resized_background_img.dataend);

    // Writing background image onto sram
    writeData(handle_0, background_img_address, img_vector);

    // setup 11 case <-- no need for the last case?
    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 1);

    // Writing background image onto sram
    writeData(handle_0, background_img_address, img_vector);

    //bool test_switch = 0;

    int index = 0;
    std::string directory = "/home/pi/Desktop/test_images/PETS2006/input/";
    std::string img_name = "in000003.jpg";
    std::string result_img_directory = "/home/pi/Desktop/test_images/test_results/";
    std::string result_img_name = "out000000.jpg";

    // Variables for results
    std::vector<uchar> result_vector;

    int execute_counter = 0;
    int idle_counter = 0;

    // main loop
    while (1)
    {
        while (1) {
            if (gpioRead(inst_valid && fpga_idle)) {
                gpioWrite(fpga_execute, 1);
                break;
            }

            execute_counter++;

            if (execute_counter > 1000) {
                std::cout << "Unable to execute tasks." << std::endl;
                return 1;
            }
        }
        //gpioWrite(fpga_execute, 1);

        //setup current case
        // Load the image
        std::string img_full_path = directory + img_name;
        img = cv::imread(img_full_path, cv::IMREAD_COLOR);

        // Check if the image is loaded successfully
        if(img.empty())
        {
            std::cout << "Could not read the image." << std::endl;
            return 1;
        }
        
        // Resize the image to 128x128
        cv::resize(img, resized_img, cv::Size(128, 128));

        // Convert the resized image to a single vector
        img_vector.assign(resized_img.datastart, resized_img.dataend);

        // Writing data onto sram
        writeData(handle_0, current_img_address, img_vector);

        // Wait till fpga is done
        while (!fpga_working) {
            idle_counter ++;

            if (idle_counter > 10000) {
                std::cout << "FPGA is unable to complete execution." << std::endl;
                return 1;
            }
        }

        fpga_working = 0;
        idle_counter = 0;

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
        result_vector = readData(handle_0, result_img_address, 16384);
        cv::Mat result_img(128, 128, CV_8UC1, result_vector.data());

        std::string result_full_path = result_img_directory + result_img_name;
        // Save the restored image
        cv::imwrite(result_full_path, result_img);

        index++;

        if (index < 10){
            result_img_name = "out00000" + std::to_string(index) + ".jpg";
        } else if (index < 100) {
            result_img_name = "out0000" + std::to_string(index) + ".jpg";
        } else if (index < 1000) {
            result_img_name = "out000" + std::to_string(index) + ".jpg";
        } else {
            result_img_name = "out00" + std::to_string(index) + ".jpg";
        }

        if (index + 3 < 10){
            img_name = "in00000" + std::to_string(index + 3) + ".jpg";
        } else if (index + 3< 100) {
            img_name = "in0000" + std::to_string(index + 3) + ".jpg";
        } else if (index + 3< 1000) {
            img_name = "in000" + std::to_string(index + 3) + ".jpg";
        } else {
            img_name = "in00" + std::to_string(index + 3) + ".jpg";
        }


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

/*
#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

#define CHANNEL 0
#define SPEED 5000000
#define READ 0x03
#define WRITE 0x02

// g++ -o fpga_controller fpga_controller.cpp `pkg-config --cflags --libs opencv` -lpigpio -lrt -lpthread
// sudo ./fpga_controller

// GPIO pin number
// TODO: ENTER THE RIGHT GPIO PIN NUMBERS
const int sram_select_0 = 24; //GPIO 0 is physical pin 11
const int sram_select_1 = 23;
const int inst_valid = 17;
const int fpga_idle = 27;
const int fpga_execute= 22;

// sram addresses for current image, background image, and result image
const int result_img_address = 0;
const int current_img_address = 16385;
const int background_img_address = 65538;

// Function to write uchar to the SRAM chip.
void writeData(int handle, int address, std::vector<uchar> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

// Function to read uchar from the SRAM chip.
std::vector<uchar> readData(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<uchar>(buffer.begin() + 4, buffer.end());
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
*/

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

    // Convert the vector back to a Mat
    cv::Mat restored_img(128, 128, CV_8UC3, img_vector.data());

    // Save the restored image
    cv::imwrite("restored_image.jpg", restored_img);

    return 0;
}
In this code, cv::Mat restored_img(128, 128, CV_8UC3, img_vector.data()); creates a new cv::Mat object from the vector data. 128, 128 are the dimensions of the image, CV_8UC3 specifies that the matrix has 8-bit unsigned integers and 3 channels (i.e., it's a color image), and img_vector.data() is a pointer to the vector's data. Then, cv::imwrite("restored_image.jpg", restored_img); saves the image to a file.

Note that when converting the vector back to a cv::Mat, you need to know the original dimensions and type of the image. In this case, you know that the image is 128x128 and has 3 channels because you resized it to those dimensions before flattening it.

*/