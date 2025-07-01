#include <iostream>
#include <opencv2/opencv.hpp>
#include <opencv2/core/cuda.hpp>
#include <opencv2/cudafilters.hpp>
#include <opencv2/cudaimgproc.hpp>
#include <opencv2/cudaarithm.hpp>


using namespace cv;
using namespace std;

int main(int argc, char** argv) {
    VideoCapture cap;
    bool use_camera = true;
    bool save_video = false;

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

    int frame_width = static_cast<int>(cap.get(CAP_PROP_FRAME_WIDTH));
    int frame_height = static_cast<int>(cap.get(CAP_PROP_FRAME_HEIGHT));
    int fps = static_cast<int>(cap.get(CAP_PROP_FPS));
    if (fps == 0) fps = 35;

    VideoWriter writer;
    if (save_video) {
        writer.open("output.avi", VideoWriter::fourcc('M','J','P','G'), fps, Size(frame_width, frame_height), false);
        if (!writer.isOpened()) {
            cerr << "Error: Could not open the video writer." << endl;
            return -1;
        }
        cout << "Video recording enabled, saving to output.avi" << endl;
    }

    Ptr<cuda::Filter> sobel_x = cuda::createSobelFilter(CV_8UC1, CV_16S, 1, 0, 3);
    Ptr<cuda::Filter> sobel_y = cuda::createSobelFilter(CV_8UC1, CV_16S, 0, 1, 3);

    Mat frame;
    cuda::GpuMat d_frame, d_gray, d_grad_x, d_grad_y, d_abs_grad_x, d_abs_grad_y, d_grad;

    cout << "Press 'q' to quit." << endl;

    while (true) {
        cap >> frame;
        if (frame.empty()) break;

        d_frame.upload(frame);
        cuda::cvtColor(d_frame, d_gray, COLOR_BGR2GRAY);

        sobel_x->apply(d_gray, d_grad_x);
        sobel_y->apply(d_gray, d_grad_y);

        cuda::abs(d_grad_x, d_abs_grad_x);
        cuda::abs(d_grad_y, d_abs_grad_y);

        cuda::addWeighted(d_abs_grad_x, 0.5, d_abs_grad_y, 0.5, 0, d_grad);

        cuda::GpuMat d_grad_8u;
        d_grad.convertTo(d_grad_8u, CV_8U);

        Mat grad;
        d_grad_8u.download(grad);

        imshow("Original", frame);
        imshow("CUDA Sobel", grad);

        if (save_video) {
            writer.write(grad);
        }

        if ((char)waitKey(1) == 'q') break;
    }

    cap.release();
    if (save_video) writer.release();
    destroyAllWindows();

    return 0;
}
