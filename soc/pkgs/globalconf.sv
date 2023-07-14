package globalconf;
  //**************************** MEMORY/BUS ****************************
  //Memory sizes - specify the address width in bits, which is log2(memory size in bytes)
  parameter MEM_BOOTROM_ADDR_WIDTH = 13;  //8 KB Boot ROM
  parameter MEM_RAM_ADDR_WIDTH = 16;  //64 KB main RAM
  parameter MEM_FRAMEBUFFER_ADDR_WIDTH = 18;  //up to 256 KB framebuffer - actual size set below

  //Memory initialization files - either "none" or filename of .mem file
`ifdef XILINX_SIMULATOR
  parameter MEM_BOOTROM_INIT = "sim_bootrom.mem";
  parameter MEM_RAM_INIT = "sim_ram.mem";
`else
  parameter MEM_BOOTROM_INIT = "bootloader.mem";
  parameter MEM_RAM_INIT = "none";
`endif

  //Memory latencies in clock cycles (+1 inherent latency)
  parameter MEM_BOOTROM_LATENCY = 1;
  parameter MEM_RAM_LATENCY = 7;
  parameter MEM_PERIPHERAL_LATENCY = 0;
  parameter MEM_FRAMEBUFFER_LATENCY = 3;

  //Address space definitions
  parameter ADDR_SLAVE_COUNT = 7;
  parameter ADDR_BOOTROM_START = 'h1A000000;
  parameter ADDR_BOOTROM_END = 'h1A001FFF;
  parameter ADDR_SOCCON_START = 'h1B000000;
  parameter ADDR_SOCCON_END = 'h1B000FFF;
  parameter ADDR_GPIO_START = 'h1B001000;
  parameter ADDR_GPIO_END = 'h1B001FFF;
  parameter ADDR_TIMERS_START = 'h1B002000;
  parameter ADDR_TIMERS_END = 'h1B002FFF;
  parameter ADDR_PWM_START = 'h1B003000;
  parameter ADDR_PWM_END = 'h1B003FFF;
  parameter ADDR_RAM_START = 'h1C000000;
  parameter ADDR_RAM_END = 'h1C00FFFF;
  parameter ADDR_FRAMEBUFFER_START = 'h1D000000;
  parameter ADDR_FRAMEBUFFER_END = 'h1D03FFFF;



  //**************************** CLOCK ****************************
  //Main clock - by default, configured for 25 MHz
  parameter CLK_MAIN_DIVIDER = 32;  //divider down from 800Mhz, 1-128
  //VGA clock - by default, configured for 25 MHz (requirement for 640x480 display)
  parameter CLK_VGA_DIVIDER = 32;  //divider down from 800Mhz, 1-128
  //UART clock - by default, configured for 500 kBaud -> 8 MHz clock
  parameter CLK_UART_DIVIDER_PLL = 100;  //divider down from 800Mhz, 1-128
  parameter CLK_UART_DIVIDER_POST = 1; //post-divider after PLL division, either 1 or a multiple of 2



  //**************************** VIDEO ****************************
  //Video framebuffer size in bits - see a few options below.
  //640px*300px*8bit/px=1536000 (32:15)
  //640px*360px*8bit/px=1843200 (16:9)
  parameter VIDEO_FB_MEM_SIZE = 1843200;

  //VGA output properties
  parameter VIDEO_VGA_OFFSET = 60; //vertical offset of image in 640x480 frame (640x480: 0, 640x360: 60, 640x300: 90)
  parameter VIDEO_VGA_FIRST_LINE = 95; //first line index that is active (640x480: 35, 640x360: 95, 640x300: 125)
  parameter VIDEO_VGA_LAST_LINE = 455; //first line index that is active (640x480: 515, 640x360: 455, 640x300: 425)



  //**************************** PERIPHERALS ****************************
  //GPIO port count - each port provides the hardware for 32 GPIO pins, maximum 16 ports
  parameter GPIO_PORT_COUNT = 1;

  //Timer count - how many independent timer modules there are, maximum 16 modules
  parameter TIMER_COUNT = 2;

  //PWM module count - each module can drive one GPIO pin in PWM mode, maximum 16 modules
  parameter PWM_MODULE_COUNT = 6;

endpackage
