# gMUXBypass

## Overview
This HDL overwrites the configuration on the Lattice XP2 on the 820-2914 and 820-2915 boards to buffer the iGPU LVDS signals directly to the LCD. It also powers down the dGPU to conserve power

## Synthesised Variants
There are two variants that can be synthesised; PWM and NoPWM. This is selectable by setting USE_PWM in the module parameter definitions. There are also pre-built JEDECs available in the repo if you don't wish to synthesise these yourself. They can be flashed using the standalone Lattice Diamond Programmer.

| Variant | USE_PWM | Pre-built JEDEC File |  Description |
| ------ | ------ | ------ | ------ |
| NoPWM | 0 | gMUXBypass_NoPWM.jed | 100% duty-cycle brightness. FPGA_N2 is tied high. |
| PWM | 1 | gMUXBypass_PWM.jed | Brightness controlled by PCH. FPGA_N2 is tied floating. Need to connect LCD_BKLT_PWM to NC_LVDS_IG_BKL_PWM. |

The NoPWM variant has no brightness control. It will never be possible to perform brightness control via the LPC interface natively, as the AppleMuxControl.kext responsible for managing the FPGA gMUX is contained within AppleGraphicsControl.kext, which in turn is only loaded if the dGPU is present on PCIe. It may be possible to write a new extension which just sends brightness control commands over the LPC interface (Lattice has a free LPC IP block [here](http://www.latticesemi.com/en/Products/DesignSoftwareAndIP/IntellectualProperty/ReferenceDesigns/ReferenceDesigns02/LPCBusController)), however this is likely a lot more work and isn't necessarily update-proof.

For this reason, the second variant has been created. This simply sets the N2 (LCD_BKLT_PWM) output of the FPGA high-impedance so an external source is free to drive it. The NC_LVDS_IG_BKL_PWM signal from the PCH is then connected up to LCD_BKLT_PWM (I used R9693-1 for my implementation) so the iGPU has full control over the panel brightness. This makes the 820-2915 functionally identical to the 820-2936 from a brightness control perspective. As far as the OS is concerned, this is a integrated-only system.

## Hardware Modification
Due to the loss of the post on advancedreworks, I have put all the critical information needed for connecting up the PWM signal from the PCH here. It is not as complete a guide as the forum post was, but this is all I have time for right now.

The location of the PCH interposer via we're interested in is as follows:

![](https://i.imgur.com/KAq5CQj.jpg)

Once you have located this point, mark it with a small nick in the solder mask. Proceed to then scratch at the mask layer until you hit the first ground plane layer.

![](https://i.imgur.com/BsqFgd3.jpg)

Cut through this with your pick and continue through the dielectric below. You should see feint evidence of the top of the via. Continue removing dielectric material until you reach the shiny copper top.

![](https://i.imgur.com/Cy9zhGx.jpg)

How you choose to connect to this via is up to you at this point. I used some copper tape mounted to the interposer, and one strand of a scrap piece of stranded wire. The copper tape gives strain relief through mechanical isolation. Images below to serve as an example.

![](https://i.imgur.com/EXfDMqz.jpg)

![](https://i.imgur.com/kMBgHvU.jpg)

![](https://i.imgur.com/sYzBekX.jpg)

![](https://i.imgur.com/qrKkgje.jpg)

I ran the connection to pin 1 of R9693 (LCD_BKLT_PWM) on my implementaion. However after updating my version of OBV, I noticed there appears to be a test point on the PCH side just below C9623 that may also be used. This should save from having to run the wire to the other side of the board.

## Disclaimer
I am not responsible for any damage this causes. This has been tested on an 820-2915 successfully, but YMMV. The FPGA's original configuration cannot be backed up. This means this process is irreversable and once reprogrammed, the original configuration programmed by Apple will be irrecoverably lost.

## License
GPL

# Added by Romain - New Variant - PWM Controlled by BIL Button

## Introduction
Since the hardware modification and micro-soldering proposed above was too complicated for me, I tried to implement another RTL design in the Lattice FPGA.
This new variant : 
- Generates a configurable 650Hz PWM signal to control the backlight
- Initial brightness setting at boot is 10/16
- The PWM is configured with 16 pre-defined settings, similar than the one proposed the original Apple hardware
- The settings can be changed by pressing 1/2 second on the BIL (Backlight Indicator Led) button of your MBP
- Pressing several time or keeping your finger on the button will allow to cycle through all the settings. When Max brightness mode is reached, the loop restart at lower brightness.

## Hardware modification
The design requires 1 wire to be soldered (easier than the PCH soldering), to connect : 
- The GMUX_PL6A free input of the Lattice FPGA. It is available on R9647 (nostuff). You will also see that a testpoint exist close to the Lattice.
- The SMC_BIL_BUTTON_L signal, available on C6954.

Both connections are on the same side of the board and the wire is pretty straight.
Note that these indications are for a 15 inch MBP motherboard. But with signal names you will be able to find-out the proper connection on another model.

![](https://i.imgur.com/4O0boMl.png)

## JDEC file
The JDEC file is located on the JDEC folder and is named GMUX_PWM_BIL_Button.jed

## Source file
The source file has not been checked-in yet, since I am not expert in github.
They are anyway available for anybody who want them.

## Misc information
This designed has been tested successfully on 2 different 15' MBP (820-2915)
The "black screen" setting (zero backlight) is not implemented because I don't like it (always have the feeling that computer is broken). If you need/want it it can be added in a few minutes.

