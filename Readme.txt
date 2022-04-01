MHLib Programming Library for MultiHarp 150/160 
Version 3.1.0.0
PicoQuant GmbH - March 2022



Introduction

The MultiHarp 150/160 is a TCSPC system with USB 3.0 interface. 
The system requires a 686 class PC with suitable USB host controller,
4 GB of memory, two or more CPU cores and at least 2 GHz CPU clock. 
The MultiHarp software is supported on Windows 8.1, 10 and 11 
including the x64 versions. 
The programming library is a DLL with demos for various programming 
languages. Please refer to the manual (PDF) for instructions.


What's new in version 3.1

- Supports event filtering in hardware 
- Supports compression of overflow records in TTTR mode 
  and enables a mild compression by default  
- Provides a new function MH_SetSyncChannelEnable
- Allows measurements over 100h under software control
- New demos for instant TTTR data processing
- New demos for event filtering
- New demos for multiple devices
- Now officially supporting Windows 11


What was new in version 3.0

- Support of the new hardware model MultiHarp 160 
- Support of the external FPGA interface (EFI) of the MultiHarp 160 
- Support of the programmable input hysteresis of the MultiHarp 160 
- Fixes a critical bug where in previous versions the call of some 
  White Rabbit functions might damage the content of the device EEPROMs
- Fixes a bug where the return time of MH_ReadFifo was very long


What was new in version 2.0

- Supporting the new high resolution models MultiHarp 150  4P/8P/16P 
- Providing a new device driver supporting "secure boot" with Windows 10 
- Some minor bugfixes 


What was new in version 1.1

- Support for the new 16-channel hardware
- Programmable dead-time (requires suitable firmware)
- Some minor bugfixes


Disclaimer

PicoQuant GmbH disclaims all warranties with regard to this software 
including all implied warranties of merchantability and fitness. 
In no case shall PicoQuant GmbH be liable for any direct, indirect or 
consequential damages or any material or immaterial damages whatsoever 
resulting from loss of data, time or profits; arising from use, inability 
to use, or performance of this software and associated documentation. 


License and Copyright Notice

With the MultiHarp hardware product you have purchased a license to use 
the MHLib software. You have not purchased other rights to the software. 
The software is protected by copyright and intellectual property laws. 
You may not distribute the software to third parties or reverse engineer, 
decompile or disassemble the software or part thereof. You may use and 
modify demo code to create your own software. Original or modified demo 
code may be re-distributed, provided that the original disclaimer and 
copyright notes are not removed from it. Copyright of the manual and 
on-line documentation belongs to PicoQuant GmbH. No parts of it may be 
reproduced, translated or transferred to third parties without written 
permission of PicoQuant GmbH. 


Acknowledgements

The MultiHarp hardware in its current version as of March 2022 
uses the White Rabbit PTP core v. 4.0
(https://www.ohwr.org/projects/wr-cores/wiki/wrpc-release-v40) licensed 
under the CERN Open Hardware Licence v1.1 and its embedded WRPC software 
(https://ohwr.org/projects/wrpc-sw/wikis/home) licensed under GPL 
Version 2, June 1991. The WRPC software was minimally modified and in 
order to meet the licensing terms the modified WRPC source code is 
provided as part of the MultiHarp software distribution media.


Trademark Disclaimer

Products and corporate names appearing in the product manuals or in the 
online documentation may or may not be registered trademarks or copyrights 
of their respective owners. They are used only for identification or 
explanation and to the owner’s benefit, without intent to infringe.


Installation 

Before installation, make sure to backup any work you kept in previous
installation directories and uninstall any previous installations of MHLib.
The MHLib package can be distributed on CD/DVD, or via download.
The setup distribution file is setup.exe.
If you received the package via download it will be packed in a 
zip-file. Unzip that file and place the distribution setup file in a 
temporary disk folder. Start the installation by running setup.exe before
connecting the MultiHarp device.

The setup program will install the programming library including manual 
and programming demos. Note that the demos create output files and must 
have write access in the folder where you run them. This may not be the 
case in the default installation folder. If need be, please adjust the 
acces permissions or copy the demos to a suitable folder.

Before uninstalling the MHLib package, please backup your measurement data 
and custom programs.
From the start menu select:  PicoQuant - MultiHarp-MHLib vx.x  >  uninstall.
Alternatively you can use the Control Panel Wizard 'Add/Remove Programs'
(in some Windows versions this Wizard is called 'Software')


Contact and Support

PicoQuant GmbH
Rudower Chaussee 29
12489 Berlin, Germany
Phone +49 30 1208820-0
Fax   +49 30 1208820-90
email info@picoquant.com
www http://www.picoquant.com
