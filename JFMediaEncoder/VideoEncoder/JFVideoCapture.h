//
//  JFVideoCapture.h
//  HardCoding
//
//  Created by 黄鹏飞 on 2021/4/9.
//  Copyright © 2021 黄鹏飞. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface JFVideoCapture : NSObject

- (void)startCapture:(UIView *)preView;

- (void)stopCapture;

- (BOOL)isRunning;
@end

NS_ASSUME_NONNULL_END
