//
//  testViewController.m
//  QiniuDemo
//
//  Created by WorkSpace_Sun on 2018/11/6.
//  Copyright © 2018 Aaron. All rights reserved.
//

#import "testViewController.h"
#import "QNTempFile.h"

NSString *token = @"Oh5V7tcC3YiXDpQaXf6GMn_dIOVzQBnW9j4UZePS:AW18qay4f_DMOTajnAas4EhvN_o=:eyJzY29wZSI6InB1cnN1ZSIsImRlYWRsaW5lIjoxNTQxNjU4NzAwfQo=";

@interface testViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) UIImage *pickImage;
@property (nonatomic, strong) NSMutableArray *urlArray;

@property (nonatomic, assign) int fileSize;
@end

@implementation testViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.urlArray = [NSMutableArray array];
    self.fileSize = 120 * 1024;
    
    [self initButton];
}

- (void)dealloc
{
    NSLog(@"dealloc success!");
}

- (void)initButton {
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setTitle:@"生成" forState:UIControlStateNormal];
    button1.backgroundColor = [UIColor orangeColor];
    button1.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 200) / 2.0, 100, 200, 50);
    [button1 addTarget:self action:@selector(generateAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button2 setTitle:@"上传" forState:UIControlStateNormal];
    button2.backgroundColor = [UIColor orangeColor];
    button2.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 200) / 2.0, 200, 200, 50);
    [button2 addTarget:self action:@selector(uploadAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeCustom];
    [button3 setTitle:@"返回" forState:UIControlStateNormal];
    button3.backgroundColor = [UIColor orangeColor];
    button3.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 200) / 2.0, 300, 200, 50);
    [button3 addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
}

- (void)uploadWithPiece:(NSString *)filePath key:(NSString *)key {
    
    NSLog(@"uploadkey: %@", key);
    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
        NSLog(@"percent == %.2f", percent);
    } params:nil checkCrc:NO cancellationSignal:nil];
    
    [upManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"info ===== %@", info);
        NSLog(@"resp ===== %@", resp);
        
    } option:uploadOption];
}

- (void)uploadWithRecorder:(NSString *)filePath key:(NSString *)key {
    
    NSLog(@"uploadkey: %@", key);
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSError *error = nil;
    QNFileRecorder *file = [QNFileRecorder fileRecorderWithFolder:[NSTemporaryDirectory() stringByAppendingString:@"qiniutest"] error:&error];
    NSLog(@"recorder error %@", error);
    QNUploadManager *upManager = [[QNUploadManager alloc] initWithRecorder:file];
    
    __block BOOL flag = NO;
    
    //    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
        if (percent >= 0.5) {
            flag = YES;
        }
        NSLog(@"percent == %.2f", percent);
    }
                                                                 params:nil
                                                               checkCrc:NO
                                                     cancellationSignal:^BOOL() {
                                                         return flag;
                                                     }];
    
    
    
    [upManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"info ===== %@", info);
        NSLog(@"resp ===== %@", resp);
        
        dispatch_semaphore_signal(semaphore);
    }
                option:uploadOption];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    __block BOOL failed = NO;
    
    uploadOption = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
        if (percent < 0.5 - 2 * 1024.0 / self.fileSize) {
            failed = YES;
        }
        NSLog(@"continue progress %f,%f", percent, 0.5 - 2 * 1024.0 / self.fileSize);
    }
                                                 params:nil
                                               checkCrc:NO
                                     cancellationSignal:nil];
    
    [upManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"info ===== %@", info);
        NSLog(@"resp ===== %@", resp);
        
        NSLog(@"isSuccess: %d", !failed);
    } option:uploadOption];
    
}

- (void)generateAction:(UIButton *)sender {
    
    sender.backgroundColor = [UIColor grayColor];
    sender.enabled = NO;
    for (NSInteger i = 0; i < 1; i++) {
        [self.urlArray addObject:[QNTempFile createTempfileWithSize:self.fileSize * 1024]];
//            [self.urlArray addObject:[[NSBundle mainBundle] URLForResource:@"IMG_4130" withExtension:@"m4v"]];
    }
}

- (void)uploadAction:(UIButton *)sender {
    

    if (self.urlArray.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"还未选择图片"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    } else {
        sender.enabled = NO;
        sender.backgroundColor = [UIColor grayColor];
        for (NSURL *fileUrl  in self.urlArray) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self uploadWithPiece:fileUrl.path key:[NSString stringWithFormat:@"Sun:uploadtest: %d", arc4random() % 100000]];
                //            [self uploadWithRecorder:fileUrl.path key:[NSString stringWithFormat:@"13:uploadtest: %d", arc4random() % 100000]];
            });
        }
    }
}

- (void)backAction {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
