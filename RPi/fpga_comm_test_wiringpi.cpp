#include <iostream>
#include <wiringPi.h>
#include <wiringPiSPI.h>

constexpr uint8_t READ = 0x03;
constexpr uint8_t WRITE = 0x02;
constexpr uint8_t RDSR = 0x05;
constexpr uint8_t WRSR = 0x01;

//g++ -o sram_test sram_test.cpp -lwiringPi
//./sram_test


int spi_channel = 1; // SPI Channel (0 or 1)

const int sram_select0 = 24;
const int sram_select1 = 23;
const int inst_valid = 17;
const int job_done = 27;
const int execute_task = 22;

void write_byte(uint32_t address, uint8_t value) {
    uint8_t buffer[5] = {WRITE, static_cast<uint8_t>((address >> 16) & 0xFF), static_cast<uint8_t>((address >> 8) & 0xFF), static_cast<uint8_t>(address & 0xFF), value};
    wiringPiSPIDataRW(spi_channel, buffer, 5);
}

void write_array(uint32_t address, uint8_t* value, int size) {
    uint8_t buffer[size + 4];
    buffer[0] = WRITE;
    buffer[1] = static_cast<uint8_t>((address >> 16) & 0xFF);
    buffer[2] = static_cast<uint8_t>((address >> 8) & 0xFF);
    buffer[3] = static_cast<uint8_t>(address & 0xFF);
    
    for(int i = 0; i < size; i++) {
        buffer[i + 4] = value[i];
    }
    digitalWrite(10, LOW);
    wiringPiSPIDataRW(spi_channel, buffer, size + 4);
    digitalWrite(10, HIGH);
}

uint8_t read_byte(uint32_t address) {
    uint8_t buffer[5] = {READ, static_cast<uint8_t>((address >> 16) & 0xFF), static_cast<uint8_t>((address >> 8) & 0xFF), static_cast<uint8_t>(address & 0xFF), 0x00};
    wiringPiSPIDataRW(spi_channel, buffer, 5);
    return buffer[4];
}

void read_arr(uint32_t address, uint8_t* arr, int size) {
    uint8_t buffer[size + 4];
    buffer[0] = READ;
    buffer[1] = static_cast<uint8_t>((address >> 16) & 0xFF);
    buffer[2] = static_cast<uint8_t>((address >> 8) & 0xFF);
    buffer[3] = static_cast<uint8_t>(address & 0xFF);
    
    digitalWrite(10, LOW);
    wiringPiSPIDataRW(spi_channel, buffer, size + 4);
    digitalWrite(10, HIGH);
    for (int i = 0; i < size; i++) {
        arr[i] = buffer[4 + i];
    }
}

int main() {
    wiringPiSetup(); // Initialize WiringPi library
    int spi_fd = wiringPiSPISetup(spi_channel, 100000); // Initialize SPI with a speed of 10kHz

    if (spi_fd == -1) {
        std::cerr << "Error initializing SPI" << std::endl;
        return 1;
    }
    
    // digitalWrite(10, HIGH);
    
    // int test_num = 5423;
    // uint8_t buffer[4];
    // buffer[0] = static_cast<uint8_t>((test_num >> 24) & 0xFF);
    // buffer[1] = static_cast<uint8_t>((test_num >> 16) & 0xFF);
    // buffer[2] = static_cast<uint8_t>((test_num >> 8) & 0xFF);
    // buffer[3] = static_cast<uint8_t>(test_num & 0xFF);
    // wiringPiSPIDataRW(spi_channel, buffer, 4);
    
    // Set the pin mode
    pinMode(sram_select0, OUTPUT);
    pinMode(sram_select1, OUTPUT);
    pinMode(inst_valid, INPUT);
    pinMode(job_done, INPUT);
    pinMode(execute_task, OUTPUT);

    for (int i = 0; i < 50; i++) {
        digitalWrite(sram_select0, LOW);
        digitalWrite(sram_select1, LOW);
        digitalWrite(execute_task, LOW);
        delay(1000);

        digitalWrite(sram_select0, LOW);
        digitalWrite(sram_select1, LOW);
        digitalWrite(execute_task, HIGH);
        delay(1000);

        digitalWrite(sram_select0, LOW);
        digitalWrite(sram_select1, HIGH);
        digitalWrite(execute_task, LOW);
        delay(1000);

        digitalWrite(sram_select0, LOW);
        digitalWrite(sram_select1, HIGH);
        digitalWrite(execute_task, HIGH);
        delay(1000);

        digitalWrite(sram_select0, HIGH);
        digitalWrite(sram_select1, LOW);
        digitalWrite(execute_task, LOW);
        delay(1000);

        digitalWrite(sram_select0, HIGH);
        digitalWrite(sram_select1, LOW);
        digitalWrite(execute_task, HIGH);
        delay(1000);

        digitalWrite(sram_select0, HIGH);
        digitalWrite(sram_select1, HIGH);
        digitalWrite(execute_task, LOW);
        delay(1000);

        digitalWrite(sram_select0, HIGH);
        digitalWrite(sram_select1, HIGH);
        digitalWrite(execute_task, HIGH);
        delay(1000);
    }

    return 0;
}
