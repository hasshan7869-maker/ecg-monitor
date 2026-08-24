/* ============================================================
 * ECG Monitor - PIC24FJ64GA002
 * Reads AD8232 output on AN0, sends value over UART1 (RP9=TX, RP10=RX)
 * as ASCII decimal text, one reading per line, for MATLAB to parse.
 * ============================================================ */

/* FCY must be defined BEFORE including libpic30.h, or __delay_ms()/
 * __delay_us() won't expand correctly and you'll get "undefined
 * reference" errors at link time. */
#define FCY 4000000UL   /* FRC (8MHz) / 2 = instruction cycle rate */

#include <p24FJ64GA002.h>   /* MPLAB C30 device header (not xc.h) */
#include <stdio.h>
#include <libpic30.h>

/* NOTE ON CONFIG BITS (MPLAB 8 / C30):
 * Don't hand-type _CONFIG macros from a chat window - the exact bit
 * names shift between device header versions and getting one wrong
 * just wastes your time on build errors. Instead, in MPLAB 8:
 *   Configure menu > Configuration Bits
 * Set: Oscillator = FRC (no PLL), Watchdog Timer = disabled,
 * JTAG = disabled. Right-click in that window > "Generate Source Code
 * to Output" and paste the exact _CONFIG lines it gives you right
 * above InitADC() below. That guarantees correct names for your
 * exact compiler/header version.
 */

_CONFIG2( FNOSC_FRC & FCKSM_CSDCMD & OSCIOFNC_ON & POSCMOD_NONE );
_CONFIG1( JTAGEN_OFF & GCP_OFF & GWRP_OFF & BKBUG_OFF & COE_OFF & ICS_PGx1 & FWDTEN_OFF );

void InitADC(void);
void InitUART(void);
unsigned int ReadADC(void);
void UART_SendString(char *str);

int main(void) {
    char buffer[16];
    unsigned int adcValue;

    InitADC();
    InitUART();

    while (1) {
        adcValue = ReadADC();
        sprintf(buffer, "%u\r\n", adcValue);
        UART_SendString(buffer);
        __delay_ms(4);   /* ~250 samples/sec */
    }
    return 0;
}

/* ---- ADC: AN0 (pin 2) as analog input, manual sample/convert ---- */
void InitADC(void) {
    AD1PCFGbits.PCFG0 = 0;    /* AN0 = analog (default is digital!) */
    TRISAbits.TRISA0 = 1;     /* RA0/AN0 as input */

    AD1CON1bits.FORM  = 0;    /* output as plain integer */
    AD1CON1bits.SSRC  = 7;    /* auto-convert after sample time ends */
    AD1CON1bits.ASAM  = 0;    /* we start sampling manually in code */

    AD1CON2 = 0;               /* AVdd/AVss as +/- voltage reference */

    AD1CON3bits.SAMC = 16;     /* auto-sample time */
    AD1CON3bits.ADCS = 2;      /* A/D conversion clock select */

    AD1CHSbits.CH0SA = 0;      /* channel 0 positive input = AN0 */

    AD1CON1bits.ADON = 1;      /* turn ADC module on */
}

unsigned int ReadADC(void) {
    AD1CON1bits.SAMP = 1;          /* begin sampling */
    __delay_us(5);
    AD1CON1bits.SAMP = 0;          /* end sampling, start conversion */
    while (!AD1CON1bits.DONE);     /* wait for conversion to finish */
    return ADC1BUF0;
}

/* ---- UART1 on remapped pins RP9 (TX, pin 18) / RP10 (RX, pin 21) ---- */
void InitUART(void) {
    __builtin_write_OSCCONL(OSCCON & 0xBF);  /* unlock PPS */
    RPOR4bits.RP9R   = 3;    /* RP9  -> U1TX (RP9 lives in the paired RPOR4 register) */
    RPINR18bits.U1RXR = 10;  /* RP10 -> U1RX */
    __builtin_write_OSCCONL(OSCCON | 0x40);  /* lock PPS */

    U1MODEbits.UARTEN = 0;
    U1MODEbits.BRGH   = 0;   /* standard speed mode */
    U1BRG             = 25;  /* ~9600 baud at Fcy = 4MHz */
    U1MODEbits.PDSEL  = 0;   /* 8 data bits, no parity */
    U1MODEbits.STSEL  = 0;   /* 1 stop bit */

	U1MODEbits.UARTEN = 1;   /* enable UART module */
    U1STAbits.UTXEN  = 1;    /* enable transmitter */
    
}

void UART_SendString(char *str) {
    while (*str) {
        while (U1STAbits.UTXBF);  /* wait if TX buffer is full */
        U1TXREG = *str++;
    }
}
