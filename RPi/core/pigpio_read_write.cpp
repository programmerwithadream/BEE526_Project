extern "C" {
    #include <pigpio.h>
}

#include <iostream>
#include <pigpio.h>

#include <opencv2/opencv.hpp>
#include <vector>
#include <string>
#include <chrono>
#include <thread>

#define CHANNEL 0
#define SPEED 5000000
#define READ 0x03
#define WRITE 0x02

const int sram_select_0 = 24; //GPIO 0 is physical pin 11
const int sram_select_1 = 23;

// g++ pigpio_read_write.cpp -o pigpio_read_write -lpigpio -lrt
// sudo ./pigpio_read_write

// Function to write char to the SRAM chip.
void writeChar(int handle, int address, std::vector<char> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

// Function to read char from the SRAM chip.
std::vector<char> readChar(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<char>(buffer.begin() + 4, buffer.end());
}

// Function to write uint8_t to the SRAM chip.
void writeData(int handle, int address, std::vector<uint8_t> data) {
    std::vector<uint8_t> buffer = {WRITE, (uint8_t)((address>>16)&0xFF), (uint8_t)((address>>8)&0xFF), (uint8_t)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, reinterpret_cast<char*>(&buffer[0]), buffer.size());
}

// Function to read uint8_t from the SRAM chip.
std::vector<uint8_t> readData(int handle, int address, int length) {
    std::vector<uint8_t> buffer = {READ, (uint8_t)((address>>16)&0xFF), (uint8_t)((address>>8)&0xFF), (uint8_t)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, reinterpret_cast<char*>(&buffer[0]), reinterpret_cast<char*>(&buffer[0]), buffer.size());

    return std::vector<uint8_t>(buffer.begin() + 4, buffer.end());
}

int main() {
    // Initialise the pigpio library
    if (gpioInitialise() < 0) {
        std::cout << "Could not initialise pigpio\n";
        return 1;
    }

    // Open SPI channel
    int handle = spiOpen(CHANNEL, SPEED, 0);

    
    gpioWrite(sram_select_0, 0);
    gpioWrite(sram_select_1, 0);

    int length = 16384;

    // Read the data back
    std::vector<uint8_t> readBack = readData(handle, 0x000000, length);

    // Print the read data
    for (int i = 0; i < length; i++) {
        std::cout << "Address " << i << " contains: " << unsigned(readBack[i]) << std::endl;
    }
    std::cout << std::endl;

    // Close SPI channel
    spiClose(handle);

    // Terminate the pigpio library
    gpioTerminate();

    return 0;
}
