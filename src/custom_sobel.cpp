#include <iostream>
#include <chrono>
#include <opencv2/opencv.hpp>

// Include the CUDA kernel functions
extern "C" void processImageWithCUDA(const cv::Mat& input, cv::Mat& output, int threshold);

using namespace cv;
using namespace std;

int threshold_value = 100; // Default threshold value
int max_threshold = 255;

int main(int argc, char** argv) {
    auto start = chrono::high_resolution_clock::now();
    int frame_count = 0;
    float fps = 0.0;

    VideoCapture cap;
    bool use_camera = true;
    bool save_video = false;

    // Parse command line arguments
    if (argc > 1) {
        cap.open(argv[1]);
        use_camera = false;
        if (argc > 2 && string(argv[2]) == "save") {
            save_video = true;
        }
    } else {
        cap.open(0);
    }

    if (!cap.isOpened()) {
        cerr << "Error: Could not open video source." << endl;
        return -1;
    }

    // Get video properties
    int frame_width = static_cast<int>(cap.get(CAP_PROP_FRAME_WIDTH));
    int frame_height = static_cast<int>(cap.get(CAP_PROP_FRAME_HEIGHT));
    int cap_fps = static_cast<int>(cap.get(CAP_PROP_FPS));
    if (cap_fps == 0) cap_fps = 30;

    // Setup video writer if saving is enabled
    VideoWriter writer;
    if (save_video) {
        writer.open("custom_sobel_output.avi", VideoWriter::fourcc('M','J','P','G'), 
                   cap_fps, Size(frame_width, frame_height), false);
        if (!writer.isOpened()) {
            cerr << "Error: Could not open the video writer." << endl;
            return -1;
        }
        cout << "Video recording enabled, saving to custom_sobel_output.avi" << endl;
    }

    Mat frame, processed_frame;
    
    cout << "Custom CUDA Sobel Edge Detection" << endl;
    cout << "Press 'q' to quit." << endl;

    namedWindow("Custom CUDA Sobel", WINDOW_NORMAL);
    createTrackbar("Threshold", "Custom CUDA Sobel", &threshold_value, max_threshold);

    while (true) {
        frame_count++;
        auto current_time = chrono::high_resolution_clock::now();
        auto duration = chrono::duration_cast<chrono::milliseconds>(current_time - start);
        float seconds = duration.count() / 1000.0f;

        if (seconds >= 0.5) {  
            fps = frame_count / seconds;
            start = current_time;  
            frame_count = 0;
        }

        cap >> frame;
        if (frame.empty()) break;

        // Process frame with custom CUDA kernel
        processImageWithCUDA(frame, processed_frame, threshold_value);

        // Add FPS text to original frame
        putText(frame, "FPS: " + to_string(int(fps + 0.5f)), Point(10, 30), 
                FONT_HERSHEY_SIMPLEX, 1, Scalar(0, 255, 0), 2);

        // Display results
        imshow("Original", frame);
        imshow("Custom CUDA Sobel", processed_frame);

        // Save video if enabled
        if (save_video) {
            writer.write(processed_frame);
        }

        if ((char)waitKey(1) == 'q') break;
    }

    cap.release();
    if (save_video) writer.release();
    destroyAllWindows();

    return 0;
} 