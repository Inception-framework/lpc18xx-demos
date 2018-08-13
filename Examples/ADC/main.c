/*******************************************************************************
*
* Project: LPC1850-DB1 Development Board Examples
*
* Description: Main code for "ADC" example.
*
* Copyright by Diolan Ltd. All rights reserved.
*
*******************************************************************************/


#include "lpc18xx.h"
#include "lpc1850_db1.h"
#include "lpc18xx_adc.h"
#include "lpc18xx_scu.h"
#include "lpc18xx_cgu.h"


volatile uint16_t adcResults[5] = { ~0, ~0, ~0, ~0, ~0 };


// ADC0 interrupt. Used only to read channel 4 data
void ADC0_IRQHandler(void)
{
    // Check if conversion finishes
    if (ADC_ChannelGetStatus(LPC_ADC0, ADC_CHANNEL_4, ADC_DATA_DONE) == SET)
    {
        // Read ADC result
        adcResults[4] = ADC_ChannelGetData(LPC_ADC0, ADC_CHANNEL_4);
        // Disable interrupt
        ADC_IntConfig(LPC_ADC0, ADC_ADINTEN4, DISABLE);
    }
}


int main(void)
{
    //SystemInit();
    CGU_Init();


    printf(" Init ADC0: 200 kHz sampling rate, 10 bits \n\n");
    ADC_Init(LPC_ADC0, 200000, 10);
    ADC_IntConfig(LPC_ADC0, ADC_ADGINTEN, DISABLE); // global interrupt is enabled by default
    NVIC_EnableIRQ(ADC0_IRQn);                      // enable interupt in NVIC


    //===========================================
    printf(" Get ADC result on channel 3 using polling \n");
    //===========================================

    printf(" Enable channel 3 \n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_3, ENABLE);

    printf(" Start single conversion \n");
    ADC_StartCmd(LPC_ADC0, ADC_START_NOW);
    printf(" Wait for DONE bit set \n");
    while (ADC_ChannelGetStatus(LPC_ADC0, ADC_CHANNEL_3, ADC_DATA_DONE) != SET);

    printf(" Read result (pin12): ");
    adcResults[3] = ADC_ChannelGetData(LPC_ADC0, ADC_CHANNEL_3);
    printf("%d\n",adcResults[3]);
    
    printf(" Disable channel \n\n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_3, DISABLE);


    //=============================================
    printf(" Get ADC result on channel 4 using interrupt \n");
    //=============================================

    printf(" Enable channel 4 \n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_4, ENABLE);
    printf(" Enable interrupt for channel 1 \n");
    ADC_IntConfig(LPC_ADC0, ADC_ADINTEN4, ENABLE);

    printf(" Start single conversion \n");
    ADC_StartCmd(LPC_ADC0, ADC_START_NOW);
    printf(" Wait for result to be read in interrupt (pin13): ");
    while (adcResults[4] == (uint16_t)~0);
    printf("%d\n",adcResults[4]);
    
    printf(" Disable channel \n\n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_4, DISABLE);


    //================================================
    printf(" Get ADC result on channels 0 and 1 using burst \n");
    //================================================

    printf(" Enable channel 0 \n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_0, ENABLE);
    printf(" Enable channel 1 \n");
    ADC_ChannelCmd(LPC_ADC0, ADC_CHANNEL_1, ENABLE);
    printf(" Enable burst \n");
    ADC_StartCmd(LPC_ADC0, ADC_START_CONTINUOUS);   // start must be = 0 when enabling burst
    ADC_BurstCmd(LPC_ADC0, ENABLE);

    int i;
    for(i=0;i<3;i++)
    //while (1)
    {
        uint32_t dr;

        // Data read can be done using ADC_ChannelGetStatus() and ADC_ChannelGetData(),
        // but this functions reads data register 2 times

        printf(" Read channel 0 (pin9) result: ");
        dr = LPC_ADC0->DR[0];
        if (dr & ADC_DR_DONE_FLAG)
        {
            adcResults[0] = ADC_DR_RESULT(dr);
            printf("%d\n",adcResults[0]);
        }

        printf(" Read channel 1 (pin10) result: ");
        dr = LPC_ADC0->DR[1];
        if (dr & ADC_DR_DONE_FLAG)
        {
            adcResults[1] = ADC_DR_RESULT(dr);
            printf("%d\n",adcResults[1]);
        }
    }
}
