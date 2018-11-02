//
//  ViewController.m
//  QiniuDemo
//
//  Created by   何舒 on 16/3/2.
//  Copyright © 2016年 Aaron. All rights reserved.
//

#import "ViewController.h"
#import "QNTempFile.h"

NSString *token = @"Oh5V7tcC3YiXDpQaXf6GMn_dIOVzQBnW9j4UZePS:btJb8QToiRyCVljgNL_FD7jc4uI=:eyJzY29wZSI6InB1cnN1ZSIsImRlYWRsaW5lIjoxNTQxMTQ3MDI5fQo=";

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) UIImage *pickImage;
@property (nonatomic, strong) NSMutableArray *urlArray;

@property (nonatomic, assign) int fileSize;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"七牛云上传";
    self.urlArray = [NSMutableArray array];
    self.fileSize = 20 * 1024;
}

- (IBAction)chooseAction:(id)sender {
    //    [self gotoImageLibrary];
    
    for (NSInteger i = 0; i < 1; i++) {
        [self.urlArray addObject:[QNTempFile createTempfileWithSize:self.fileSize * 1024]];
        //        [self.urlArray addObject:[[NSBundle mainBundle] URLForResource:@"IMG_4130" withExtension:@"m4v"]];
    }
}

- (IBAction)uploadAction:(id)sender {
    if (self.urlArray.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"还未选择图片"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    } else {
        for (NSURL *fileUrl  in self.urlArray) {
            [self uploadWithPiece:fileUrl.path key:[NSString stringWithFormat:@"13:uploadtest: %d", arc4random() % 100000]];
            //            [self uploadWithRecorder:fileUrl.path key:[NSString stringWithFormat:@"13:uploadtest: %d", arc4random() % 100000]];
        }
    }
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

- (void)gotoImageLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"访问图片库错误"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert show];
    }
}

//再调用以下委托：
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    self.pickImage = image; //imageView为自己定义的UIImageView
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//照片获取本地路径转换
- (NSString *)getImagePath:(UIImage *)Image {
    NSString *filePath = nil;
    NSData *data = nil;
    if (UIImagePNGRepresentation(Image) == nil) {
        data = UIImageJPEGRepresentation(Image, 1.0);
    } else {
        data = UIImagePNGRepresentation(Image);
    }

    //图片保存的路径
    //这里将图片放在沙盒的documents文件夹中
    NSString *DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];

    //文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];

    //把刚刚图片转换的data对象拷贝至沙盒中
    [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *ImagePath = [[NSString alloc] initWithFormat:@"/theFirstImage.png"];
    [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:ImagePath] contents:data attributes:nil];

    //得到选择后沙盒中图片的完整路径
    filePath = [[NSString alloc] initWithFormat:@"%@%@", DocumentsPath, ImagePath];
    return filePath;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
