#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/highgui.hpp>
#include <vector>
#include <string>
#include <chrono>
#include <thread>
#include <array>


#define CHANNEL_0 0
#define CHANNEL_1 1
#define SPEED 5000000
#define READ 0x03
#define WRITE 0x02

// g++ -o real_time_background_subtraction real_time_background_subtraction.cpp `pkg-config --cflags --libs opencv` -lpigpio -lrt -lpthread
// sudo ./real_time_background_subtraction
// g++ -o real_time_background_subtraction real_time_background_subtraction.cpp `pkg-config --cflags --libs opencv` -lrt -lpthread

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

const int DEVICE_ID = 0;
const int API_ID = cv::CAP_ANY;

//Function to write uchar to the SRAM chip.
void writeData(int handle, int address, std::vector<uchar> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

//Function to read uchar from the SRAM chip.
std::vector<uchar> readData(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<uchar>(buffer.begin() + 4, buffer.end());
}

//This function will be called every time fpga stops being idle
//to ensure fpga_execute pins returns low
void notIdle(int gpio, int level, uint32_t tick)
{
    if (level == 0) {
        gpioWrite(fpga_execute, 0);
        fpga_working = 1;
    }
    
    // std::cout << "FPGA executing..." << std::endl;
}

void load_background_subtraction_inst(int handle) {
    uint32_t uint_result_img_address = (uint32_t) result_img_address;
    uint32_t uint_current_img_address = (uint32_t) current_img_address;
    uint32_t uint_background_img_address = (uint32_t) background_img_address;
    std::vector<char> buffer = {0xFF, (char)((uint_result_img_address>>16)&0xFF), (char)((uint_result_img_address>>8)&0xFF), (char)((uint_result_img_address)&0xFF), (char)((uint_current_img_address>>16)&0xFF), (char)((uint_current_img_address>>8)&0xFF), (char)((uint_current_img_address)&0xFF), (char)((uint_background_img_address>>16)&0xFF), (char)((uint_background_img_address>>8)&0xFF), (char)((uint_background_img_address)&0xFF)};

    spiWrite(handle, &buffer[0], 10);
}

int main() {
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
        std::this_thread::sleep_for(std::chrono::milliseconds(15));
        if(inst_valid_counter > 10) {
            std::cout << "unable to load instruction onto FPGA." << std::endl;
            return 1;
        }
        inst_valid_counter++;
    }

    // initializing opencv video capture
    cv::VideoCapture cap;
    cv::Mat frame;
    cv::Mat resized_frame;
    cv::Mat background_frame;
    cv::Mat result_frame;
    std::vector<uchar> resized_frame_vec;
    std::vector<uchar> background_frame_vec;
    std::vector<uchar> result_frame_vec;

    cap.open(DEVICE_ID, API_ID);

    if(!cap.isOpened()) {
        std::cout << "Unable to establish connection with camera." << std::endl;
        return 1;
    }

    // Setting up background images onto srams
    cap.read(frame);

    if (frame.empty()) {
        std::cout << "Could not read the image." << std::endl;
        return 1;
    }

    cv::resize(frame, resized_frame, cv::Size(128, 128));
    cv::resize(frame, background_frame, cv::Size(128, 128));

    resized_frame_vec.assign(resized_frame.datastart, resized_frame.dataend);
    background_frame_vec.assign(background_frame.datastart, background_frame.dataend);

    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 0);

    writeData(handle_0, current_img_address, resized_frame_vec);
    writeData(handle_0, background_img_address, background_frame_vec);

    std::this_thread::sleep_for(std::chrono::milliseconds(15));

    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 0);

    writeData(handle_0, current_img_address, resized_frame_vec);
    writeData(handle_0, background_img_address, background_frame_vec);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(15));

    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 1);

    writeData(handle_0, current_img_address, resized_frame_vec);
    writeData(handle_0, background_img_address, background_frame_vec);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(15));

    gpioWrite(sram_select_0, 1);
    gpioWrite(sram_select_1, 1);

    writeData(handle_0, current_img_address, resized_frame_vec);
    writeData(handle_0, background_img_address, background_frame_vec);
    
    std::this_thread::sleep_for(std::chrono::milliseconds(15));
    
    int execute_counter = 0;
    int idle_counter = 0;

    while (true) {
        while (1) {
            if (gpioRead(inst_valid) && gpioRead(fpga_idle)) {
                gpioWrite(fpga_execute, 1);
                break;
            }

            execute_counter++;

            if (execute_counter > 1000) {
                std::cout << "Unable to execute tasks." << std::endl;
                return 1;
            }
        }

        // Load the image
        cap.read(frame);

        if (frame.empty()) {
            std::cout << "Could not read the image." << std::endl;
            return 1;
        }
        
        cv::resize(frame, resized_frame, cv::Size(128, 128));

        //cv::imshow("resized_frame", resized_frame);

        resized_frame_vec.assign(resized_frame.datastart, resized_frame.dataend);

        writeData(handle_0, current_img_address, resized_frame_vec);

        // Wait till fpga is done
        while (!fpga_working | !gpioRead(fpga_idle)) {
            idle_counter++;

            if (idle_counter > 1000000000) {
                std::cout << "FPGA is unable to complete execution." << std::endl;
                return 1;
            }
        }

        fpga_working = 0;
        idle_counter = 0;

        if (gpioRead(sram_select_0) == 0 && gpioRead(sram_select_1) == 0) {
            gpioWrite(sram_select_0, 1);
            gpioWrite(sram_select_1, 0);
        } else if (gpioRead(sram_select_0) == 1 && gpioRead(sram_select_1) == 0) {
            gpioWrite(sram_select_0, 0);
            gpioWrite(sram_select_1, 1);
        } else if (gpioRead(sram_select_0) == 0 && gpioRead(sram_select_1) == 1) {
            gpioWrite(sram_select_0, 1);
            gpioWrite(sram_select_1, 1);
        } else {
            gpioWrite(sram_select_0, 0);
            gpioWrite(sram_select_1, 0);
        }

        result_frame_vec = readData(handle_0, result_img_address, 16384);
        cv::Mat temp(128, 128, CV_8UC1, result_frame_vec.data());
        result_frame = temp;

        
        // std::this_thread::sleep_for(std::chrono::milliseconds(15));
        cv::imshow("result frame", result_frame);
        // std::this_thread::sleep_for(std::chrono::milliseconds(50));

        // If any key is pressed, convert the frame variable to a vector
        if (cv::waitKey(5) >= 0) {
        //     // Setting up background images onto srams
        //     cap.read(frame);

        //     if (frame.empty()) {
        //         std::cout << "Could not read the image." << std::endl;
        //         return 1;
        //     }

        //     cv::resize(frame, resized_frame, cv::Size(128, 128));
        //     cv::resize(frame, background_frame, cv::Size(128, 128));

        //     resized_frame_vec.assign(resized_frame.datastart, resized_frame.dataend);
        //     background_frame_vec.assign(background_frame.datastart, background_frame.dataend);

        //     gpioWrite(sram_select_0, 0);
        //     gpioWrite(sram_select_1, 0);

        //     writeData(handle_0, current_img_address, resized_frame_vec);
        //     writeData(handle_0, background_img_address, background_frame_vec);

        //     std::this_thread::sleep_for(std::chrono::milliseconds(15));

        //     gpioWrite(sram_select_0, 1);
        //     gpioWrite(sram_select_1, 0);

        //     writeData(handle_0, current_img_address, resized_frame_vec);
        //     writeData(handle_0, background_img_address, background_frame_vec);
            
        //     std::this_thread::sleep_for(std::chrono::milliseconds(15));

        //     gpioWrite(sram_select_0, 0);
        //     gpioWrite(sram_select_1, 1);

        //     writeData(handle_0, current_img_address, resized_frame_vec);
        //     writeData(handle_0, background_img_address, background_frame_vec);
            
        //     std::this_thread::sleep_for(std::chrono::milliseconds(15));

        //     gpioWrite(sram_select_0, 1);
        //     gpioWrite(sram_select_1, 1);

        //     writeData(handle_0, current_img_address, resized_frame_vec);
        //     writeData(handle_0, background_img_address, background_frame_vec);
            
        //     std::this_thread::sleep_for(std::chrono::milliseconds(15));
        }
    }

    spiClose(handle_0);
    spiClose(handle_1);

    // Terminate pigpio library
    gpioTerminate();

    return 0;
}