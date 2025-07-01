# Makefile for Custom CUDA Sobel Project

# Compilers
NVCC = nvcc
CXX = g++

# Flags
NVCC_FLAGS = -O3 -arch=sm_50
CXX_FLAGS = -std=c++14 -O3
OPENCV_FLAGS = $(shell pkg-config --cflags opencv4)
OPENCV_LIBS = $(shell pkg-config --libs opencv4)
CUDA_LIBS = -lcudart

# Directories
SRC_DIR = src
BUILD_DIR = build
INCLUDE_DIR = -I/usr/local/include/opencv4 -I/usr/local/cuda/include
LIB_DIR = -L/usr/local/lib -L/usr/local/cuda/lib64

# Targets
TARGET = custom_sobel
KERNEL_LIB = libsobel_kernels.so

# Source files
KERNEL_SRC = $(SRC_DIR)/sobel_kernel.cu
MAIN_SRC = $(SRC_DIR)/custom_sobel.cpp

# Object files
KERNEL_OBJ = $(BUILD_DIR)/sobel_kernel.o
MAIN_OBJ = $(BUILD_DIR)/custom_sobel.o

# Default target
all: $(BUILD_DIR) $(TARGET)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile CUDA kernel library
$(KERNEL_OBJ): $(KERNEL_SRC)
	$(NVCC) $(NVCC_FLAGS) $(INCLUDE_DIR) -c $< -o $@

$(KERNEL_LIB): $(KERNEL_OBJ)
	$(NVCC) $(NVCC_FLAGS) --shared -o $@ $< $(OPENCV_LIBS) $(CUDA_LIBS)

# Compile main application
$(MAIN_OBJ): $(MAIN_SRC)
	$(CXX) $(CXX_FLAGS) $(OPENCV_FLAGS) $(INCLUDE_DIR) -c $< -o $@

# Link everything together
$(TARGET): $(MAIN_OBJ) $(KERNEL_LIB)
	$(CXX) $(CXX_FLAGS) -o $@ $< -L. -lsobel_kernels $(OPENCV_LIBS) $(CUDA_LIBS) $(LIB_DIR)

# Alternative: Direct compilation without separate library
direct: $(BUILD_DIR)
	$(NVCC) $(NVCC_FLAGS) $(INCLUDE_DIR) $(LIB_DIR) \
		$(KERNEL_SRC) $(MAIN_SRC) \
		-o $(TARGET) \
		$(OPENCV_LIBS) $(CUDA_LIBS)

# Clean
clean:
	rm -rf $(BUILD_DIR) $(TARGET) $(KERNEL_LIB)

# Run
run: $(TARGET)
	./$(TARGET)

# Run with camera
camera: $(TARGET)
	./$(TARGET) 0

# Run with video file
video: $(TARGET)
	./$(TARGET) video.mp4

# Run with video file and save output
save: $(TARGET)
	./$(TARGET) video.mp4 save

# Help
help:
	@echo "Available targets:"
	@echo "  all     - Build the complete project"
	@echo "  direct  - Direct compilation (alternative)"
	@echo "  clean   - Remove build files"
	@echo "  run     - Run with default camera"
	@echo "  camera  - Run with camera (explicit)"
	@echo "  video   - Run with video file"
	@echo "  save    - Run with video file and save output"
	@echo "  help    - Show this help"

.PHONY: all clean run camera video save help direct 