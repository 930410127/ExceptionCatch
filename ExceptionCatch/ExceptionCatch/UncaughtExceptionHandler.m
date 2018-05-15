//
//  UncaughtExceptionHandler.m
//  ExceptionCatch
//
//  Created by 网讯 on 2018/5/14.
//  Copyright © 2018年 Jess. All rights reserved.
//

/*
 IOS SDK中提供了一个现成的函数 NSSetUncaughtExceptionHandler 用来做异常处理，但功能非常有限，而引起崩溃的大多数原因如：内存访问错误，重复释放等错误就无能为力了，因为这种错误它抛出的是Signal，所以必须要专门做Signal处理。
 */

#import "UncaughtExceptionHandler.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>

volatile int32_t UncaughtExceptionCount =0;
const int32_t UncaughtExceptionMaximum =10;

NSString * const UncaughtExceptionHandlerSignalExceptionName=@"UncaughtExceptionHandlerSignalExceptionName";

NSString * const UncaughtExceptionHandlerAddressesKey=@"UncaughtExceptionHandlerAddressesKey";
NSString * const UncaughtExceptionHandlerSignalKey=@"UncaughtExceptionHandlerSignalKey";

const NSInteger UncaughtExceptionHandlerReportAddressCount = 10;//指明报告多少条调用堆栈信息

@interface UncaughtExceptionHandler(){
    
    BOOL dismissed;//是否继续程序
}

@end

@implementation UncaughtExceptionHandler



+ (NSArray *)backtrace{
    void * callstack[128];//堆栈方法数组
    int frames = backtrace(callstack, 128);//从backtrace中获取错误堆栈方法指针数组，返回数目
    char ** strs = backtrace_symbols(callstack, frames);//符号化
    
    int i;
    NSMutableArray *symbolsBacktrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = 0; i < UncaughtExceptionHandlerReportAddressCount; i++) {
        [symbolsBacktrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return symbolsBacktrace;
}

- (void)handlerException:(NSException *)exception{
    NSString *message=[NSString stringWithFormat:@"如果点击继续，程序有可能会出现其他的问题，建议您还是点击退出按钮并重新打开\n\n异常报告:\n异常名称：%@\n异常原因：%@\n其他信息：%@\n",
                       [exception name],
                       [exception reason],
                       [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"抱歉，程序出现了异常" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dismissed = YES;
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dismissed = NO;
    }];
    [alert addAction:action];
    [alert addAction:cancel];
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [rootViewController presentViewController:alert animated:YES completion:nil];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    while (!dismissed) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    CFRelease(allModes);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqualToString:UncaughtExceptionHandlerSignalExceptionName]) {
        kill(getpid(), [[[exception userInfo]objectForKey:UncaughtExceptionHandlerSignalKey]intValue]);
    }else{
        [exception raise];
    }
}

@end

/** 处理异常的方法
 *
 */

void uncaughtExceptionHandler(NSException *exception){
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    // 如果太多不用处理
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    //获取调用堆栈信息
    NSArray *callStack = [exception callStackSymbols];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[UncaughtExceptionHandler alloc]init] performSelectorOnMainThread:@selector(handlerException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
}

/** 处理信号异常的方法
 *
 */

void mySignalHandler(int signal){
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    // 如果太多不用处理
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[NSException alloc]init] performSelectorOnMainThread:@selector(handlerException:) withObject:[NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.",signal] userInfo:userInfo] waitUntilDone:YES];
}

/**开启异常的方法

 *
 */

void installUncaughtExceptionHandler(void){
    //设置未捕获的异常处理，捕捉NSException错误,当产生NSException错误时就会调用系统提供的一个现成的函数,NSSetUncaughtExceptionHandler()这里面的方法名自己随便取
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //注册SIGNAL信号
     //4:执行了非法指令. 通常是因为可执行文件本身出现错误, 或者试图执行数据段. 堆栈溢出时也有可能产生这个信号。
    signal(SIGILL, mySignalHandler);
    //程序终止调用abort函数生成的信号
    signal(SIGABRT, mySignalHandler);
    //7:非法地址, 包括内存地址对齐(alignment)出错。比如访问一个四个字长的整数, 但其地址不是4的倍数。它与SIGSEGV的区别在于后者是由于对合法存储地址的非法访问触发的(如访问不属于自己存储空间或只读存储空间)。
    signal(SIGBUS, mySignalHandler);
    //8:在发生致命的算术运算错误时发出. 不仅包括浮点运算错误, 还包括溢出及除数为0等其它所有的算术的错误
    signal(SIGFPE, mySignalHandler);
    //11:试图访问未分配给自己的内存, 或试图往没有写权限的内存地址写数据.
    signal(SIGSEGV, mySignalHandler);
    //13:管道破裂。这个信号通常在进程间通信产生，比如采用FIFO(管道)通信的两个进程，读管道没打开或者意外终止就往管道写，写进程会收到SIGPIPE信号。此外用Socket通信的两个进程，写进程在写Socket的时候，读进程已经终止。
    signal(SIGPIPE, mySignalHandler);
    //产生上述的signal的时候就会调用我们定义的mySignalHandler来处理异常
}


