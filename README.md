# Custom CUDA Sobel Edge Detection

This project implements a custom CUDA kernel for Sobel edge detection, providing full control over the GPU implementation and better understanding of the parallel processing approach.

## Project Structure

```
cuda-sobel-edge-detection/
├── src/
│   ├── sobel_kernel.cu      # Custom CUDA kernels for Sobel, Gaussian blur, RGB to Gray
│   ├── custom_sobel.cpp     # Main application using custom kernels
│   ├── main.cpp             # CPU-based Sobel implementation (for comparison)
│   └── sobel.cu             # OpenCV CUDA-based Sobel implementation
├── CMakeLists.txt           # CMake build configuration
├── Makefile                 # Alternative Makefile build system
├── LICENSE                  # Project license (MIT)
└── README.md                # Project documentation
```

## Features

- **Custom CUDA Kernels**: Hand-written Sobel edge detection kernel
- **RGB to Grayscale Conversion**: GPU-accelerated color conversion
- **Gaussian Blur**: Reduces noise before applying Sobel
- **Thresholding**: Adjustable threshold value for clearer edge maps
- **Performance Monitoring**: Real-time FPS display
- **Video Support**: Camera input and video file processing
- **Recording Capability**: Save processed video output
- **Multiple Build Systems**: Both CMake and Makefile support

## Requirements

- CUDA Toolkit (version 10.0 or higher)
- OpenCV 4.x with CUDA support
- GCC/G++ compiler
- CMake (optional, for CMake build)

## Building the Project

### Option 1: Using Makefile (Recommended)

```bash
# Build the project
make direct

# Clean build files
make clean

# Show available targets
make help
```

### Option 2: Using CMake

```bash
# Create build directory
mkdir build && cd build

# Configure and build
cmake ..
make

# Or build in one command
cmake --build .
```

### Option 3: Manual Compilation

```bash
# Compile custom CUDA Sobel
nvcc -O3 -arch=sm_50 -I/usr/local/include/opencv4 -I/usr/local/cuda/include \
     -L/usr/local/lib -L/usr/local/cuda/lib64 \
     src/sobel_kernel.cu src/custom_sobel.cpp \
     -o custom_sobel \
     $(pkg-config --libs opencv4) -lcudart

# Compile CPU version
g++ src/main.cpp -o main $(pkg-config --cflags --libs opencv4)

# Compile OpenCV CUDA version
nvcc src/sobel.cu -o sobel -I/usr/local/include/opencv4 -L/usr/local/lib \
     -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_videoio \
     -lopencv_cudaimgproc -lopencv_cudafilters -lopencv_cudaarithm
```

## Running the Application

### Basic Usage

```bash
# Run with default camera
./custom_sobel

# Run with specific camera
./custom_sobel 0

# Run with video file
./custom_sobel video.mp4

# Run with video file and save output
./custom_sobel video.mp4 save
```

### Using Makefile Targets

```bash
# Run with camera
make camera

# Run with video file
make video

# Run with video file and save
make save
```

## Performance Comparison

Run all three versions to compare performance:

```bash
# CPU version (slowest)
./main

# OpenCV CUDA version (medium)
./sobel

# Custom CUDA version (fastest)
./custom_sobel
```

## CUDA Kernel Implementation

### Sobel Kernel (sobelKernel)

Implements:

    Sobel X and Y direction operators
    Boundary handling
    Grayscale magnitude: |Gx| + |Gy|
    Thresholding for binarized output

### RGB to Grayscale Kernel (rgbToGrayKernel)

Standard luminance formula:

Gray = 0.299 * R + 0.587 * G + 0.114 * B

### Gaussian Blur Kernel (gaussianBlurKernel)

Applies a 3x3 Gaussian blur:

[1 2 1]
[2 4 2]  * 1/16
[1 2 1]

Used before Sobel to suppress noise and reduce false edges.

## Troubleshooting

### Common Issues

    CUDA Architecture Mismatch
        Update -arch=sm_50 to match your GPU (e.g., sm_61, sm_86)
        Use nvidia-smi or deviceQuery to check compute capability
    OpenCV Not Found
        Install OpenCV with CUDA support
        Ensure pkg-config finds it: pkg-config --cflags --libs opencv4
    CUDA Runtime Errors
        Check CUDA installation: nvcc --version
        Verify GPU drivers: nvidia-smi
    Linker Errors
        Wrap CUDA kernels with extern "C" when calling from C++
        Link with -lcudart and OpenCV libraries

### Debug Mode

To enable debugging flags, edit the Makefile:

NVCC_FLAGS = -g -G -O0 -arch=sm_50
CXX_FLAGS = -std=c++14 -g -O0

## License

This project is open source. Feel free to use and modify as needed.
