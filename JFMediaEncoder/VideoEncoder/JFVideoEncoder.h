//
//  JFVideoEncoder.h
//  HardCoding
//
//  Created by 黄鹏飞 on 2021/4/9.
//  Copyright © 2021 黄鹏飞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface JFVideoEncoder : NSObject

- (void)startEncoderForSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)endEncoder;
@end

NS_ASSUME_NONNULL_END
