extern "C" {
    #include <pigpio.h>
}

#include <iostream>
#include <vector>

#define CHANNEL 0
#define SPEED 500000
#define READ 0x03
#define WRITE 0x02

// sudo apt-get update
// sudo apt-get install pigpio

// Function to write data to the SRAM chip.
void writeData(int handle, int address, std::vector<char> data) {
    std::vector<char> buffer = {WRITE, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.insert(buffer.end(), data.begin(), data.end());
    
    spiWrite(handle, &buffer[0], buffer.size());
}

// Function to read data from the SRAM chip.
std::vector<char> readData(int handle, int address, int length) {
    std::vector<char> buffer = {READ, (char)((address>>16)&0xFF), (char)((address>>8)&0xFF), (char)(address&0xFF)};
    buffer.resize(4 + length);

    spiXfer(handle, &buffer[0], &buffer[0], buffer.size());

    return std::vector<char>(buffer.begin() + 4, buffer.end());
}

int main() {
    // Initialise the pigpio library
    if (gpioInitialise() < 0) {
        std::cout << "Could not initialise pigpio\n";
        return 1;
    }

    // Open SPI channel
    int handle = spiOpen(CHANNEL, SPEED, 0);

    // Write some data
    std::vector<char> dataToWrite = {'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd'};
    writeData(handle, 0x000000, dataToWrite);

    // Read the data back
    std::vector<char> readBack = readData(handle, 0x000000, dataToWrite.size());

    // Print the read data
    for (char c : readBack) {
        std::cout << c;
    }
    std::cout << std::endl;

    // Close SPI channel
    spiClose(handle);

    // Terminate the pigpio library
    gpioTerminate();

    return 0;
}