Unfortunately we have no LabVIEW for Linux.
Please take the LabVIEW demos from the demo set of MHLib for 
Windows, open it under LabVIEW for Linux and replace the 
library path name with

/usr/local/lib/mh150/mhlib.so
or
/usr/lib/libmh150.so (symlink created by install script)

dependent on where and how you installed the library.
The LabVIEW demos shoud then also run under Linux.
