#include <cuda_runtime.h>
#include <opencv2/opencv.hpp>
#include <iostream>

using namespace cv;
using namespace std;

// CUDA kernel for Sobel edge detection
__global__ void sobelKernel(const unsigned char* input, unsigned char* output, 
                           int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x >= width || y >= height) return;
    
    // Sobel kernels
    const int sobelX[3][3] = {{-1, 0, 1}, {-2, 0, 2}, {-1, 0, 1}};
    const int sobelY[3][3] = {{-1, -2, -1}, {0, 0, 0}, {1, 2, 1}};
    
    int gx = 0, gy = 0;
    
    // Apply Sobel kernels
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            int nx = x + i;
            int ny = y + j;
            
            // Handle boundary conditions
            if (nx < 0) nx = 0;
            if (nx >= width) nx = width - 1;
            if (ny < 0) ny = 0;
            if (ny >= height) ny = height - 1;
            
            int pixel = input[ny * width + nx];
            
            gx += pixel * sobelX[i + 1][j + 1];
            gy += pixel * sobelY[i + 1][j + 1];
        }
    }
    
    // Calculate magnitude
    int magnitude = (int)sqrtf((float)(gx * gx + gy * gy));
    
    // Clamp to 0-255 range
    magnitude = min(255, max(0, magnitude));
    
    output[y * width + x] = (unsigned char)magnitude;
}

// CUDA kernel for color to grayscale conversion
__global__ void rgbToGrayKernel(const unsigned char* input, unsigned char* output, 
                                int width, int height) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (x >= width || y >= height) return;
    
    int idx = (y * width + x) * 3; // 3 channels (BGR)
    
    // BGR to grayscale conversion
    unsigned char b = input[idx];
    unsigned char g = input[idx + 1];
    unsigned char r = input[idx + 2];
    
    // Use standard luminance formula
    unsigned char gray = (unsigned char)(0.299f * r + 0.587f * g + 0.114f * b);
    
    output[y * width + x] = gray;
}

// Host function to process image with CUDA
extern "C" void processImageWithCUDA(const Mat& input, Mat& output) {
    int width = input.cols;
    int height = input.rows;
    
    // Allocate device memory
    unsigned char *d_input, *d_gray, *d_output;
    size_t inputSize = width * height * 3 * sizeof(unsigned char); // BGR
    size_t graySize = width * height * sizeof(unsigned char);
    
    cudaMalloc(&d_input, inputSize);
    cudaMalloc(&d_gray, graySize);
    cudaMalloc(&d_output, graySize);
    
    // Copy input to device 
    cudaMemcpy(d_input, input.data, inputSize, cudaMemcpyHostToDevice);
    
    // Define block and grid dimensions
    dim3 blockSize(16, 16);
    dim3 gridSize((width + 15) / 16, (height + 15) / 16);
    
    // Convert to grayscale
    rgbToGrayKernel<<<gridSize, blockSize>>>(d_input, d_gray, width, height);
    
    // Apply Sobel filter
    sobelKernel<<<gridSize, blockSize>>>(d_gray, d_output, width, height);
    
    // Copy result back to host
    output = Mat(height, width, CV_8UC1);
    cudaMemcpy(output.data, d_output, graySize, cudaMemcpyDeviceToHost);
    
    // Free device memory
    cudaFree(d_input);
    cudaFree(d_gray);
    cudaFree(d_output);
    
    // Check for CUDA errors
    cudaError_t error = cudaGetLastError();
    if (error != cudaSuccess) {
        cerr << "CUDA error: " << cudaGetErrorString(error) << endl;
    }
} 


