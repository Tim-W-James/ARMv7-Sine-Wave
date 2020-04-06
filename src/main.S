.syntax unified
.global main

.type main, %function
main:
  nop
  bl init

  @ approximation of sine wave via Bhaskara I's sine approximation formula.
  @ the frequency of the sine wave will rise by 1Hz every period, 
  @ until an upper bound is reached, then fall by 1Hz every period,
  @ until a lower bound is reached, and so on

  @ customize the wave with r5 and r6.
  @ use a base frequency of 440Hz (note A),
  @ and amplitude/2 of 0x7fff for full dynamic range (max volume)

  @ r9 stores the base frequency (Hz).
  @ the frequency will change to a max of r9*2^2 (two octaves above),
  @ and r9/2^2 (two octaves below)
  mov r9, #440
  mov r5, r9

  @ r6 stores amplitude/2 (volume) or the max bound
  mov r6, 0x7fff
  
  @ r10 stores frequency mode
  mov r10, #0

  b continueA @ do not change frequency initially

change_frequency:

  @ r5 stores current frequency
modeA: @ increase frequency by 1 every period
  cmp r10, #1
  beq modeB 
  lsl r0, r9, #2 @ upper bound, two octaves above base frequency
  cmp r0, r5
  ble modeB
  add r5, #1
  b continueA
modeB: @ decrease frequency by 1 every period
  mov r10, #1
  lsr r0, r9, #2 @ lower bound, two octaves below base frequency
  cmp r0, r5
  blt continueB
  mov r10, #0
  b modeA
continueB:
  sub r5, #1
continueA:
  mov r0, #0

  @ r7 stores samples per half period
  mov r7, #48000 @ output sample rate of board (48kHz)
  udiv r7, r5 @ samples per period
  lsr r7, #1

  @ r8 stores factor to convert to degrees
  @ shifted twice for precision
  mov r8, #180
  lsl r8, #2
  lsl r0, r7, #2
  udiv r8, r7
  mov r0, #0

  nop

  @ use r4 to measure time (x axis), increments every sample, % r7

@ first half of period, positive values, peak at r6
upper_start:  
  nop
  mov r4, #0
upper_loop:
  add r4, #1 @ increase time value
  bl calculate_sample
  cmp r7, r4
  blt lower_start @ start second half of period
  bl BSP_AUDIO_OUT_Play_Sample
  b upper_loop

@ second half of period, negative values, trough at -r6
lower_start:
  nop
  mov r4, #0
lower_loop:
  add r4, #1 @ increase time value
  bl calculate_sample
  rsb r0, #0
  cmp r7, r4
  blt change_frequency @ change frequency & start first half of period (new cycle)
  bl BSP_AUDIO_OUT_Play_Sample
  b lower_loop

@ calculates sample value (y axis) based on time (x axis, r4) and amplitude/2 (r6).
@ puts result in r0, ready for sample.
@ uses Bhaskara I's sine approximation formula,
@ (4x(180-x))/(40500-x(180-x)) in addition to scaling for amplitude
calculate_sample:
  mul r1, r4, r8 @ convert to degrees (x in r1)
  lsr r1, #2
  mov r2, #180
  sub r2, r1
  mul r2, r1 @ x(180-x)
  mov r3, #4
  mul r0, r2, r3 @ 4x(180-x)
  mov r3, #40500
  sub r2, r3, r2 @ 40500-x(180-x)
  mul r0, r6 @ scale for amplitude
  udiv r0, r0, r2 @ result
  mov r1, #0
  mov r2, #0
  mov r3, #0