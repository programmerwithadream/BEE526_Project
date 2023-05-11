#include <iostream>
#include <wiringPi.h>
#include <wiringPiSPI.h>

constexpr uint8_t READ = 0x03;
constexpr uint8_t WRITE = 0x02;
constexpr uint8_t RDSR = 0x05;
constexpr uint8_t WRSR = 0x01;

//g++ -o sram_test sram_test.cpp -lwiringPi
//./sram_test


int spi_channel = 0; // SPI Channel (0 or 1)

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
    int spi_fd = wiringPiSPISetup(spi_channel, 10000000); // Initialize SPI with a speed of 10kHz

    if (spi_fd == -1) {
        std::cerr << "Error initializing SPI" << std::endl;
        return 1;
    }
    
    digitalWrite(10, HIGH);
    
    //int test = 257;
    //uint8_t testuint = test;
    //std::cout << "test result: " << static_cast<int>(testuint) << std::endl;
    
    uint8_t testarr[100];
    for (uint8_t i = 0; i < 100; i++) {
        testarr[i] = i ;
    }
    
    // Write data to SRAM
    std::cout << "Writing data to SRAM..." << std::endl;
    write_array(0, testarr, 100);
    delay(100);
    
    // Read data from SRAM
    std::cout << "Reading data from SRAM..." << std::endl;
    for (int i = 0; i < 100; i++) {
        uint8_t value = read_byte(i);
        std::cout << "Address " << i << ": " << static_cast<int>(value) << std::endl;
    }
    
    for (uint8_t i = 0; i < 100; i++) {
        testarr[i] = i + 100;
    }
    
    // Write data to SRAM
    std::cout << "Writing data to SRAM..." << std::endl;
    write_array(0, testarr, 100);
    delay(100);
    
    uint8_t test_result[100];
    
    // Read data from SRAM
    //std::cout << "Reading data from SRAM..." << std::endl;
    //for (int i = 0; i < 100; i++) {
    //    uint8_t value = read_byte(i);
    //    std::cout << "Address " << i << ": " << static_cast<int>(value) << std::endl;
    //}
    
    read_arr(0, test_result, 100);
    for (int i = 0; i < 100; i++) {
    //    uint8_t value = read_byte(i);
        std::cout << "Address " << i << ": " << static_cast<int>(test_result[i]) << std::endl;
    }
    
    //131072
    int size = 500;
    
    uint8_t arr[size];
    for (int i = 0; i < size; i++) {
        arr[i] = i;
    }

    // Write data to SRAM
    std::cout << "Writing data to SRAM..." << std::endl;
    //for (int i = 0; i < 130; i++) {
    //    write_byte(i, i);
    //    delay(100);
    //}
    write_array(0, arr, size);
    delay(100);
    
    uint8_t result[size];

    // Read data from SRAM
    std::cout << "Reading data from SRAM..." << std::endl;
    //for (int i = 0; i < size; i++) {
    //    result[i] = read_byte(i);
    //    std::cout << "Address " << i << ": " << static_cast<int>(result[i]) << std::endl;
    //}
    
    read_arr(0, result, size);
    
    for (int i = 0; i < 100; i++) {
        std::cout << "Address " << i << ": " << static_cast<int>(result[i]) << std::endl;
    }
    
    int error_count = 0;

    for (int i = 0; i < size; i++) {
        if (arr[i] != result[i]) {
            error_count++;
        }
    }
    
    double error_count_double = (double) error_count;
    double percent_error = error_count_double / size;
    std::cout << "Percent error: " << percent_error << std::endl;
    
    
    return 0;
}
