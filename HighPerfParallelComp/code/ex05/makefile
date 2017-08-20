CC:=g++
CFLAGS:=-fopenmp
src:=$(wildcard *.cpp)

obj:=$(patsubst %.cpp,%.o,$(src))

TARGET:=ex05

$(TARGET): $(obj)
	$(CC) $(CFLAGS) $^ -o $@
%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -rf $(TARGET) $(obj)

