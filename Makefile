# Compiler
NVCC := nvcc

# Output binary
TARGET := cracker

# Source files
SRCS := src/main.cpp src/cuda_cracker.cu src/attack.cpp src/dict.cpp src/utils.cpp

# Object files
OBJS := $(SRCS:.cpp=.o)
OBJS := $(OBJS:.cu=.o)

# Compiler flags
CXXFLAGS := -Xcompiler -fopenmp -O2
LDFLAGS := -lssl -lcrypto

# Default target
all: $(TARGET)

# Link
$(TARGET): $(OBJS)
	$(NVCC) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# Compile .cpp files
%.o: %.cpp
	$(NVCC) $(CXXFLAGS) -c $< -o $@

# Compile .cu files
%.o: %.cu
	$(NVCC) $(CXXFLAGS) -c $< -o $@

# Clean
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean