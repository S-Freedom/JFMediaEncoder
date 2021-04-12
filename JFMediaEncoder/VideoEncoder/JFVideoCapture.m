//
//  JFCapture.m
//  HardCoding
//
//  Created by 黄鹏飞 on 2021/4/9.
//  Copyright © 2021 黄鹏飞. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "JFVideoCapture.h"
#import "JFVideoEncoder.h"

@interface JFVideoCapture()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer;
@property (nonatomic, strong) JFVideoEncoder *videoEncoder;
@end

@implementation JFVideoCapture

- (void)startCapture:(UIView *)preView{
    
    self.videoEncoder = [[JFVideoEncoder alloc] init];
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *deviceInputError;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceInputError];
    if([self.session canAddInput:input]){
        [self.session addInput:input];
    }
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if([self.session canAddOutput:output]){
        [self.session addOutput:output];
    }
    
    AVCaptureConnection *conn = [output connectionWithMediaType:AVMediaTypeVideo];
    [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    self.preViewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.preViewLayer.frame = preView.bounds;
    [preView.layer insertSublayer:self.preViewLayer atIndex:0];
    
    [self.session startRunning];
}

- (void)stopCapture{
    [self.session stopRunning];
    [self.preViewLayer removeFromSuperlayer];
}

- (BOOL)isRunning{
    return [self.session isRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    [self.videoEncoder startEncoderForSampleBuffer:sampleBuffer];
}

@end
