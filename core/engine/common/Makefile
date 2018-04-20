INCLUDE:=-I.  

SOURCES:=$(wildcard *.cpp)
OBJECTS:=$(SOURCES:.cpp=.o)

TARGET:=libcommon.a

.PHONY: all clean 
all: $(TARGET)

$(TARGET):$(OBJECTS)
	ar -r $@ $^ 
	ranlib $@

$(OBJECTS):%.o:%.cpp
	$(CXX) -c $(CPPFLAGS) $(INCLUDE) $< -o $@

clean:
	@rm -rf $(TARGET) $(OBJECTS)

