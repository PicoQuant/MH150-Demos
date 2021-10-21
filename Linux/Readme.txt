MHLib Programming Library for MultiHarp 150/160 
Version 3.0.0.0
PicoQuant GmbH - May 2021



Introduction

The MultiHarp 150 is a TCSPC system with USB 3.0 interface. 
The system requires a 686 class PC with suitable USB host controller,
4 GB of memory, two or more CPU cores and at least 2 GHz CPU clock.  
The programming library for Linux is a shared library with demos for 
various programming languages. Please refer to the manual (PDF) for 
further instructions.


What's new in version 3.0.0.0

- Support of the new hardware model MultiHarp 160 
- Support of the external FPGA interface (EFI) of the MultiHarp 160 
- Support of the programmable input hysteresis of the MultiHarp 160 
- Fixes a critical bug where in previous versions the call of some 
  White Rabbit functions might damage the content of the device EEPROMs
- Fixes a bug where the return time of MH_ReadFifo was very long


What was new in version 2.0.0.0

- Support for the new high resolution models MultiHarp 150 4P/8P/16P
- Some minor bugfixes and documentation improvements
- Support for x64 only, the 32-bit version has been dropped
- The API remains unchanged


What was new in version 1.1.0.0

- Support for the new 16-channel hardware
- Programmable dead-time(requires firmware version 0.8 or higher)
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

The MultiHarp hardware in its current version as of May 2021 
uses the White Rabbit PTP core v. 4.0
(https://www.ohwr.org/projects/wr-cores/wiki/wrpc-release-v40) licensed 
under the CERN Open Hardware Licence v1.1 and its embedded WRPC software 
(https://ohwr.org/projects/wrpc-sw/wikis/home) licensed under GPL 
Version 2, June 1991. The WRPC software was minimally modified and in 
order to meet the licensing terms the modified WRPC source code is 
provided as a tar.gz file. The original GPL license is included there.

When the MultiHarp software or the MultiHarp programming library is used 
under Linux it uses Libusb to access the MultiHarp USB devices. 
Libusb is licensed under the LGPL which allows a fairly free use even in 
commercial projects. For details and precise terms please see 
http://libusb.info. In order to meet the license requirements a copy of 
the LGPL as appliccable to Libusb is provided here. 
The LGPL does not apply to the MultiHarp software and library as a whole.


Trademark Disclaimer

Products and corporate names appearing in the product manuals or in the 
online documentation may or may not be registered trademarks or copyrights 
of their respective owners. They are used only for identification or 
explanation and to the owner’s benefit, without intent to infringe.


Contact and Support

PicoQuant GmbH
Rudower Chaussee 29
12489 Berlin, Germany
Phone +49 30 1208820-0
Fax   +49 30 1208820-90
email info@picoquant.com
www http://www.picoquant.com
