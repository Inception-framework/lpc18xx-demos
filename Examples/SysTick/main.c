/*******************************************************************************
*
* Project: LPC1850-DB1 Development Board Examples
*
* Description: Main code for "Buttons Leds Simple" example.
*
* Author : G. Camurati and N. Corteggiani
*
*******************************************************************************/

// Modified by Giovanni Camurati, Eurecom
// when using with Inception:
//   take all this application, except the generic irq handler, for the host
//   take only the irq handler related stuff for the stub

#include "lpc18xx.h"
#include "lpc1850_db1.h"
#include "lpc18xx_gpio.h"
#include "lpc18xx_scu.h"
#include "lpc18xx_cgu.h"

#define SysTick_Handler_ID 15

uint32_t interrupt_trace=0;
uint32_t cycleCounter = 0;
uint8_t canInc = 0;

void DelayMs(uint32_t delay)
{
    uint32_t startTime = cycleCounter;
    while ((uint32_t)(cycleCounter - startTime) <= delay);
}

void generic_irq_handler(uint32_t id){
	  // write irq id in a predefined location
	  *(uint32_t*)0x10002000 = id;

			GPIO_SetValue(7,1<<23);
	    //GPIO_SetValue(D3_GPIO_PORT, D3_GPIO_MASK);
	    while(!(GPIO_ReadValue(7) & (1<<22))){};



				//GPIO_ClearValue(D3_GPIO_PORT, D3_GPIO_MASK);
			  GPIO_ClearValue(7,1<<23);
			//while((GPIO_ReadValue(7) & (1<<22))){};

}

void SysTick_Handler(void)
{
//    cycleCounter++;
    printf("\n\n\------------>SysTick_Handler : %d\n\n",cycleCounter);
    canInc = 1;
}

int main(void)
{
    cycleCounter = 1;

    //SystemInit();
    CGU_Init();
    
    // Configure GPIO pins connected to LEDs as outputs
    scu_pinmux(D3_SCU_CONFIG);
    scu_pinmux(D4_SCU_CONFIG);
    scu_pinmux(D5_SCU_CONFIG);
    scu_pinmux(D6_SCU_CONFIG);
    GPIO_SetDir(D3_GPIO_PORT, D3_GPIO_MASK, 1);
    GPIO_SetDir(D4_GPIO_PORT, D4_GPIO_MASK, 1);
    GPIO_SetDir(D5_GPIO_PORT, D5_GPIO_MASK, 1);
    GPIO_SetDir(D6_GPIO_PORT, D6_GPIO_MASK, 1);

    // Configure GPIO pins connected to push buttons as inputs
    scu_pinmux(S1_SCU_CONFIG);
    scu_pinmux(S2_SCU_CONFIG);
    scu_pinmux(S3_SCU_CONFIG);
    scu_pinmux(S4_SCU_CONFIG);
    GPIO_SetDir(S1_GPIO_PORT, S1_GPIO_MASK, 0);
    GPIO_SetDir(S2_GPIO_PORT, S2_GPIO_MASK, 0);
    GPIO_SetDir(S3_GPIO_PORT, S3_GPIO_MASK, 0);
    GPIO_SetDir(S4_GPIO_PORT, S4_GPIO_MASK, 0);

    //while(GPIO_ReadValue(S1_GPIO_PORT) & S1_GPIO_MASK ){};

    // Init SysTick to xx (72000*tck)^-1 = 1kHz
    if(SysTick_Config(7200000)==1){
      printf("Fail to configure the systick ...\n");
      while(1);
    }

    int j=0;
    while(j++<10)
    {
        //if(j++%1000==0)
        //	printf("\n\nMAIN : %d\n\n",cycleCounter);
	while(canInc==0);
	cycleCounter++;
	canInc = 0;
    }
}
