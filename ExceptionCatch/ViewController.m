//
//  ViewController.m
//  ExceptionCatch
//
//  Created by 网讯 on 2018/5/14.
//  Copyright © 2018年 Jess. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 40, 20)];
    [button setTitle:@"异常" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)test{
    NSArray *error = @[@"1",@"2"];
    NSString *name = error[2];
    NSLog(@"%@",name);
}
@end
