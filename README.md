# JOYSTICK 1 Reader for the Nintendo Entertainment System

The boiler plate code is based on Matt Hefferman's Hello World example
https://github.com/SlithyMatt/nes-hello

I took that boiler plate code and changed:

The charset for easier hexadecimal to tile conversion

And took his "print" code and made it into a subroutine for reusabilty.

Then added my own joystick handling routines, this was quiet a challenge and in hindsight not the easiest approach to find out the "Konami Code byte string". Because the NES controller is read serially, and you can process the bits in MSB or LSB order and that would change the joystick variable value.
I learned how the Joystick worked through this document: https://d1.amobbs.com/bbs_upload782111/files_28/ourdev_551332.pdf


To build, you need to install [cc65](https://github.com/cc65/cc65), with the
executables on your path.

Then run **build.sh** from bash, or just run the build directly on the command line:

```
cl65 -t nes -o ne-joystick.nes -l ne-joystick.list ne-joystick.asm
```

You can then load ne-joystick.nes into the NES/FamiCom emulator of your choice. 
