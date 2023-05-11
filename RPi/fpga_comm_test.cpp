#include <iostream>
#include <pigpio.h>
#include <unistd.h>



//g++ -o fpga_comm_test fpga_comm_test.cpp -lpigpio -pthread
//sudo ./fpga_comm_test

const int sram_select0 = 24;
const int sram_select1 = 23;
const int inst_valid = 17;
const int job_done = 27;
const int execute_task = 22;




int main()
{
    if (gpioInitialise() < 0)
    {
        std::cerr << "Failed to initialize pigpio" << std::endl;
        return 1;
    }

    gpioSetMode(sram_select0, PI_OUTPUT);
    gpioSetMode(sram_select1, PI_OUTPUT);
    gpioSetMode(inst_valid, PI_INPUT);
    gpioSetMode(job_done, PI_INPUT);
    gpioSetMode(execute_task, PI_OUTPUT);

    for (int i = 0; i < 10; i++) {
        gpioWrite(sram_select1, 0);
        gpioWrite(sram_select0, 0);
        gpioWrite(execute_task, 0);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 0);
        gpioWrite(sram_select0, 0);
        gpioWrite(execute_task, 1);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 0);
        gpioWrite(sram_select0, 1);
        gpioWrite(execute_task, 0);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 0);
        gpioWrite(sram_select0, 1);
        gpioWrite(execute_task, 1);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 1);
        gpioWrite(sram_select0, 0);
        gpioWrite(execute_task, 0);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 1);
        gpioWrite(sram_select0, 0);
        gpioWrite(execute_task, 1);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 1);
        gpioWrite(sram_select0, 1);
        gpioWrite(execute_task, 0);
        sleep(1);             // Wait for a second

        gpioWrite(sram_select1, 1);
        gpioWrite(sram_select0, 1);
        gpioWrite(execute_task, 1);
        sleep(1);             // Wait for a second
    }

    gpioTerminate();
    return 0;
}
