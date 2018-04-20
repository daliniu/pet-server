TARGET=libmongocclient.a
all: $(TARGET)

.PHONY: all clean install

CXX=gcc
CFLAGS=-DNDEBUG -g -ggdb -Wall -DMONGO_HAVE_STDINT  -D_linux

SOURCES:=$(wildcard *.c) 
INCLUDE:=-I.
OBJECTS:=$(SOURCES:.c=.o)

$(TARGET):$(OBJECTS)
	 ar -r $(TARGET) $(OBJECTS)
	 ranlib $(TARGET)
	 rm *.d *.o -f

$(OBJECTS):%.o:%.c
	$(CXX) -c $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< -o $@


clean:
	rm -f $(TARGET) $(OBJECTS) 

install:
	cp $(TARGET) ../lib
