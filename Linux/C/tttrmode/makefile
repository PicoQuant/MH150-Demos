#
# Makefile for demo with mhlib.so


# Paths

LPATH = /usr/local/lib64/mh150/

# Flags

CC = gcc

WARN = -Wall -Wno-format
COPTS = -g -O

CFLAGS = $(WARN) $(COPTS)

# Rules

%.o: %.c
	$(CC) -c $(CFLAGS) -I$(LPATH) -o $@ $<

# Variables

BINS = tttrmode
SRCS = tttrmode.c
OBJS = $(SRCS:%.c=%.o)

# Main target

all: $(BINS)

# Dependencies

tttrmode: $(OBJS)
	$(CC) $(OBJS) $(LPATH)mhlib.so -o $@

# Misc

clean:
	rm -f *.o *~ ~* *.bck core
	rm -f $(BINS)

