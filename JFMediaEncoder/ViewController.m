//
//  ViewController.m
//  JFMediaEncoder
//
//  Created by 黄鹏飞 on 2021/4/12.
//

#import "ViewController.h"
#import "JFPerson.h"

@interface ViewController ()

@property (nonatomic, strong) JFPerson *person;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
//    CFRunLoopObserverRef runloopObserveRef = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &runLoopObserverCallBack, &context);
//    CFRunLoopAddObserver(CFRunLoopGetMain(), runloopObserveRef, kCFRunLoopCommonModes);
    
    JFPerson *person = [[JFPerson alloc] init];
    [person test];
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    switch (activity) {
        
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
            break;
        case kCFRunLoopAllActivities:
            NSLog(@"kCFRunLoopAllActivities");
            break;
    }
}



@end
