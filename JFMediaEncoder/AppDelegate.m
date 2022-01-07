//
//  AppDelegate.m
//  JFMediaEncoder
//
//  Created by 黄鹏飞 on 2021/4/12.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static int s_fatal_signals[] = {
SIGABRT,
SIGBUS,
SIGFPE,
SIGILL,
SIGSEGV,
SIGTRAP,
SIGTERM,
SIGKILL,
};
static int s_fatal_signal_num = sizeof(s_fatal_signals) / sizeof(s_fatal_signals[0]);


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    for (int i=0; i<s_fatal_signal_num; i++) {
        
        signal(s_fatal_signals[i], SignalHandler);
    }
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    return YES;
}


void SignalHandler(int code){
    NSLog(@"SignalHandler : %d",code);
}

void UncaughtExceptionHandler(NSException *exception) {
    NSArray *exceptionArray = [exception callStackSymbols]; // 得到当前调用栈信息
    NSString *exceptionReason = [exception reason]; // 非常重要，就是崩溃的原因
    NSString *exceptionName = [exception name]; // 异常类型
    NSLog(@"exceptionArray : %@", exceptionArray);
    NSLog(@"exceptionReason : %@", exceptionReason);
    NSLog(@"exceptionName : %@", exceptionName);
}

@end
