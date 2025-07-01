cmake_minimum_required(VERSION 3.10)
project(CustomCudaSobel)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(OpenCV REQUIRED)
find_package(CUDA REQUIRED)

# Include directories
include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${CUDA_INCLUDE_DIRS})

# CUDA specific settings
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS};-O3;-arch=sm_50)

# Create the custom CUDA kernel library
cuda_add_library(sobel_kernels SHARED
    src/sobel_kernel.cu
)

# Link OpenCV to the kernel library
target_link_libraries(sobel_kernels ${OpenCV_LIBS})

# Create the main application
add_executable(custom_sobel src/custom_sobel.cpp)

# Link libraries to the main application
target_link_libraries(custom_sobel 
    sobel_kernels
    ${OpenCV_LIBS}
    ${CUDA_LIBRARIES}
)

# Set CUDA properties for the main executable
set_target_properties(custom_sobel PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
)

# Add compile definitions for CUDA
target_compile_definitions(custom_sobel PRIVATE
    CUDA_API_PER_THREAD_DEFAULT_STREAM
)

# Print configuration info
message(STATUS "OpenCV version: ${OpenCV_VERSION}")
message(STATUS "CUDA version: ${CUDA_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
