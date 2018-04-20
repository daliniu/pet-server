TARGET:=Lemure
all: $(TARGET)

.PHONY: all clean install

CFLAGS=-DDEBUG -ggdb -Wall -DMONGO_HAVE_STDINT -D__LINUX__ -DLUA_COMPAT_ALL
#CFLAGS=-DDEBUG -g -Wall 

#LIBS=-lpthread -L../lib -L /usr/local/lib -L ../mongodb_c_driver   -levent -lmongocclient -L../lua -llua -lrt -ldl
LIBS=-lpthread -L../lib -L /usr/local/lib -L ../mongodb_c_driver   -levent -lmongocclient -L../lua -llua -ldl
SOURCES:=$(wildcard *.cpp) $(wildcard common/*.cpp)	$(wildcard db/*.cpp) $(wildcard aoi/*.cpp)
INCLUDE:=-I. -I./common -I./db -I../mongodb_c_driver  -I../include/libevent_inc  -I../lua
DEPENDS:=$(SOURCES:.cpp=.d)
OBJECTS:=$(SOURCES:.cpp=.o)
sinclude $(DEPENDS)

$(TARGET):$(OBJECTS)
	$(CXX) -o $@ $^ $(LIBS)

$(OBJECTS):%.o:%.cpp
	$(CXX) -c $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< -o $@

$(DEPENDS):%.d:%.cpp
	$(CXX) -MM $(CFLAGS) $(CPPFLAGS) $(INCLUDE) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

clean:
	rm -f $(TARGET) $(OBJECTS) $(DEPENDS)

install:
	cp $(TARGET) ../../bin
