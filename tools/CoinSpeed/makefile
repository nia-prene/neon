 # the compiler: gcc for C program, define as g++ for C++
CC = gcc

  # compiler flags:
  #  -g    adds debugging information to the executable file
  #  -Wall turns on most, but not all, compiler warnings
  CFLAGS  = -g -Wall 

  # the build target executable:
TARGET = main
PROGRAM = hexConverter

all: compile test

compile: $(TARGET).c
	$(CC) $(CFLAGS) -o $(PROGRAM) $(TARGET).c -lm

test: $(PROGRAM)
	./$(PROGRAM)

clean:
	$(RM) $(TARGET)
