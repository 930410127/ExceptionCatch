//
//  UncaughtExceptionHandler.h
//  ExceptionCatch
//
//  Created by 网讯 on 2018/5/14.
//  Copyright © 2018年 Jess. All rights reserved.
//

/**
 *  我们通常所接触到的崩溃主要涉及到两种：
    一：由EXC_BAD_ACCESS引起的，原因是内存访问错误，重复释放等错误
    二： 未被捕获的Objective-C异常（NSException）
     针对NSException这种错误，可以直接调用NSSetUncaughtExceptionHandler函数来捕获;而针对EXC_BAD_ACCESS错误则需通过自定义注册SIGNAL来捕获。一般产生一个NSException异常的时候，同时也会抛出一个SIGNAL的信号(当然这只是一般情况，有时可能只是会单独出现)
 

 *
 */
#import <Foundation/Foundation.h>

@interface UncaughtExceptionHandler : NSObject

@end

/**开启异常的方法
 *
 */

void installUncaughtExceptionHandler(void);
