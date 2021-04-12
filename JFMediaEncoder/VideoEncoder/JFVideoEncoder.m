//
//  JFVideoEncoder.m
//  HardCoding
//
//  Created by 黄鹏飞 on 2021/4/9.
//  Copyright © 2021 黄鹏飞. All rights reserved.
//

#import "JFVideoEncoder.h"
#import <UIKit/UIKit.h>
@interface JFVideoEncoder()

@property (nonatomic, assign) NSUInteger frameID;
@property (nonatomic, assign) VTCompressionSessionRef compressionSession;
@property (nonatomic, strong) NSFileHandle *fileHandler;
@end

@implementation JFVideoEncoder

- (instancetype)init{
    if(self = [super init]){
        
        [self setUpFileHandler];
        [self setUpVideoSession];
    }
    return self;
}

- (void)setUpFileHandler{
    
    NSFileManager *mgr = [[NSFileManager alloc] init];
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"abc.mp4"];
    NSError *error;
    [mgr removeItemAtPath:filePath error:&error];
    [mgr createFileAtPath:filePath contents:nil attributes:nil];
    self.fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
}

- (void)setUpVideoSession{
    
    //用于记录当前是第几帧数据
    self.frameID = 0;
    //录制视频的宽高
    int width = [UIScreen mainScreen].bounds.size.width;
    int height = [UIScreen mainScreen].bounds.size.height;
    
    // 创建编码器
    //VTCompressionSessionCreate 参数：(allocator,widht,height,codecType,encoderSecification,sourceImageBufferAttributes,compressedDataAllocator,outputCallback,outputCallbackRefCon,compressionSessionOut)
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, _finishCompressH264Callback, (__bridge void * _Nullable)(self), &_compressionSession);
    
    //设置实时编码，直播必然是实时输出
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    //设置期望帧数，每秒多少帧，一般都是30帧以上，以免画面卡顿
    int fps = 30;
    CFNumberRef fpsNumberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &fps);
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsNumberRef);
    
    //设置码率(码率: 编码效率, 码率越高,则画面越清晰, 如果码率较低会引起马赛克 --> 码率高有利于还原原始画面,但是也不利于传输)
    int bitRate = 800 * 1024;
    CFNumberRef bitRateNumberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, bitRateNumberRef);
    
    NSArray *limit = @[@(bitRate * 1.5/8), @(1)];
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
    
    //设置关键帧间隔（也就是GOP间隔）
    //这里设置与上面的fps一致，意味着每间隔30帧开始一个新的GOF序列，也就是每隔间隔1s生成新的GOF序列
    //因为上面设置的是，一秒30帧
    int gop = 30;
    CFNumberRef gopNumberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &gop);
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, gopNumberRef);
    
    //设置结束，准备编码
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);
}

void _finishCompressH264Callback(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer){
    
    if(status != noErr){
        return;
    }
//    NSLog(@"%@", sampleBuffer);
    //根据传入的参数获取对象
    JFVideoEncoder *videoEncoder = (__bridge JFVideoEncoder *)outputCallbackRefCon;
    
    //判断是否是关键帧
    bool keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0), kCMSampleAttachmentKey_NotSync);
    
    //如果是关键帧，获取sps & pps数据
    if(keyFrame){
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparamerSet;
        // 参数(CMFormatDescriptionRef  _Nonnull videoDesc, size_t parameterSetIndex, const uint8_t * _Nullable * _Nullable parameterSetPointerOut, size_t * _Nullable parameterSetSizeOut, size_t * _Nullable parameterSetCountOut, int * _Nullable NALUnitHeaderLengthOut)
        // 获取sps信息
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparamerSet, &sparameterSetSize, &sparameterSetCount, 0);
        
        // 获取PPS信息
        size_t pparameterSetSize, pparameterSetCount;
        const uint8_t *pparameterSet;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0);
        
        NSData *sps = [NSData dataWithBytes:sparamerSet length:sparameterSetSize];
        NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
        // 写入文件
        [videoEncoder gotSpsPps:sps pps:pps];
    }
    
    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffsetOut,totalLengthOut;
    char *dataPointOut;
    
    OSStatus pointStatus = CMBlockBufferGetDataPointer(blockBufferRef, 0, &lengthAtOffsetOut, &totalLengthOut, &dataPointOut);
    if(pointStatus == noErr){
        
        size_t bufferOffset = 0;
        // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        static const int AVCCHeaderLength = 4;
        
        while (bufferOffset < totalLengthOut - AVCCHeaderLength) {
            
            // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointOut + bufferOffset, AVCCHeaderLength);
            
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
            
            NSData *data = [[NSData alloc] initWithBytes:(dataPointOut + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            // 写入文件
            [videoEncoder gotEncodedData:data isKeyFrame:keyFrame];
            
            bufferOffset += NALUnitLength+AVCCHeaderLength;
        }
    }
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame{
    
    const char bytes[] = "\x00\x00\x01";
    size_t size = sizeof(bytes) -1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:size];
    
    if(self.fileHandler != NULL){
        [self.fileHandler writeData:ByteHeader];
        [self.fileHandler writeData:data];
    }
}

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps{

    const char bytes[] = "\x00\x00\x01";
    size_t size = sizeof(bytes) -1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:size];
    
    // 将NALU的头&NALU的体写入文件
    [self.fileHandler writeData:ByteHeader];
    [self.fileHandler writeData:sps];
    [self.fileHandler writeData:ByteHeader];
    [self.fileHandler writeData:pps];
    
    NSLog(@"写入sps, pps帧");
}

- (void)startEncoderForSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    // 编码参数(session,imageBuffer,presentationTimeStamp,duration,frameProperties,sourceFrameRefcon,infoFlagsOut)
    CVImageBufferRef imageBufferRef = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime presentationTimeStamp = CMTimeMake(self.frameID++, 1000);
    VTEncodeInfoFlags flags;
    OSStatus status = VTCompressionSessionEncodeFrame(_compressionSession, imageBufferRef, presentationTimeStamp, kCMTimeInvalid, NULL, (__bridge void * _Nullable)(self), &flags);
    
    if(status != noErr){
        NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
    }
}

- (void)endEncoder{
    VTCompressionSessionCompleteFrames(_compressionSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(_compressionSession);
    CFRelease(_compressionSession);
    _compressionSession = NULL;
}
@end
