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
    std::vector<char> buffer = {0xFF, (char)((uint_result_img_address>>16)&0xFF), (char)((uint_result_img_address>>8)&0xFF), (char)((uint_result_img_address)&0xFF), (char)((uint_current_img_address>>16)&0xFF), (char)((uint_current_img_address>>8)&0xFF), (char)((uint_current_img_address)&0xFF), (char)((uint_background_img_address>>16)&0xFF), (char)((uint_background_img_address>>8)&0xFF), (char)((uint_background_img_address)&0xFF)};

    spiWrite(handle, &buffer[0], 10);
}

int main() {
    cv::Mat frame;
    cv::VideoCapture cap;

    cap.open(DEVICE_ID, API_ID);

    if(!cap.isOpened()) {
        std::cout << "ERROR! Unable to open camera." << std::endl;
        return 1;
    }

    while (true) {
        cap.read(frame);

        if (frame.empty()) {
            std::cout << "ERROR! Blank frame." << std::endl;
            return 1;
        }

        cv::imshow("Camera Stream", frame);

        // If any key is pressed, convert the frame variable to a vector
        if (cv::waitKey(5) >= 0) {
            cv::Mat flat = frame.reshape(1, frame.total() * frame.channels());
            std::vector<uchar> img_vector = frame.isContinuous() ? flat : flat.clone();
        }
    }

    return 0;
}