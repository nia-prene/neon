# Neon engine for the NES

Neon is the name given to this NES engine. Although this particular build is suited best to a top-down bullet hell style gameplay, it can be easily retooled for almost any project with a few changes. The primary

## Getting Started

To play the current build, locate the .nes file located in the /dbg folder. All you need now is a Nintendo emulator, like fceux. All functions are in the main.s file. All ram variables are in ram.s, and all rom data can be found in the data.s. Everything has been written in a basic text editor, so no IDE or outside game engine software is necessary.

### Prerequisites

cc65 - assembling and linking the code

yy-chr - viewing and editing the graphical data

### Installing

To play the game, simply run the .nes file in the Nintendo emulator of your choice

To assemble the code, unzip the directory and open the makefile. Comment out the "test" portion (which opens the game in an emulator) and hit make in the command line. The .nes file will be located in the /dbg folder. 


## Built With

* [cc65](https://www.cc65.org/) C compiler, assembler, and linker for 6502 systems 
* [yy-chr](https://w.atwiki.jp/yychr/) - Used to edit and view graphics

## Authors

* **nia-prene** - *Initial work*


## Acknowledgments

* [The nesdev forum and wiki](www.nesdev.com)

