CC:=g++
CFLAGS:=-fopenmp
src:=$(wildcard *.c) $(wildcard *.cpp)

obj:=$(patsubst %.c, %.o,$(patsubst %.cpp,%.o,$(src)))

TARGET:=ex02

$(TARGET): $(obj)
	$(CC) $(CFLAGS) $^ -o $@
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -rf $(TARGET) $(obj)

