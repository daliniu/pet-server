TARGET:=Robot
.PHONY: all clean install

CFLAGS=-g -Wall
LIBS=-lpthread -L /usr/local/lib -levent -llua -ldl 

all: $(TARGET)

INCLUDE:=-I. -I .. -I../../lua

SOURCES:=$(wildcard *.cpp) $(wildcard ../common/*.cpp) 
DEPENDS:=$(SOURCES:.cpp=.d)
OBJECTS:=$(SOURCES:.cpp=.o)
sinclude $(DEPENDS)

$(TARGET):$(OBJECTS)
	$(CXX) -o $@ $^ $(LIBS)

$(OBJECTS):%.o:%.cpp
	$(CXX) -c $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< -o $@

#$(DEPENDS):%.d:%.cpp
#	$(CXX) -MM $(CPPFLAGS) $< > $@.$$$$; \
#	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
#	rm -f $@.$$$$

clean:
	rm -f $(TARGET) $(OBJECTS) $(DEPENDS)

install:
	cp $(TARGET) ../../../bin
