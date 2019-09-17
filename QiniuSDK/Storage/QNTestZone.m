//
//  QNTestZone.m
//  Pods-QiniuDemo
//
//  Created by WorkSpace_Sun on 2019/9/17.
//

#import "QNTestZone.h"

@implementation QNTestZone

+ (NSDictionary *)getTestResponse {
    
    NSMutableDictionary *resp = [NSMutableDictionary dictionary];
    NSMutableArray *hosts = [NSMutableArray array];
    NSDictionary *main = @{
                           @"ttl": @(86400),
                           @"io": @{
                                   @"src": @{
                                           @"main": @[@"io.src.main"]
                                           }
                                   },
                           @"up": @{
                                   @"acc": @{
                                           @"backup": @[
                                                   @"up.acc.backup1",
                                                   @"up.acc.backup2"
                                                   ],
                                           @"main": @[@"up.acc.main"]
                                           },
                                   @"old_acc": @{
                                           @"info": @"compatible to non-SNI device",
                                           @"main": @[@"up.old_acc.main"]
                                           },
                                   @"old_src": @{
                                           @"info": @"compatible to non-SNI device",
                                           @"main": @[@"up.old_src.main"]
                                           },
                                   @"src": @{
                                           @"backup": @[
                                                   @"up.src.backup1",
                                                   @"up.src.backup2"
                                                   ],
                                           @"main": @[@"up.src.main"]
                                           }
                                   }
                           };
    NSDictionary *backup = @{
                             @"ttl": @(86400),
                             @"io": @{
                                     @"src": @{
                                             @"main": @[@"io.src.main"]
                                             }
                                     },
                             @"up": @{
                                     @"acc": @{
                                             @"backup": @[
                                                     @"up.acc.backup1",
                                                     @"up.acc.backup2"
                                                     ],
                                             @"main": @[@"up.acc.main"]
                                             },
                                     @"old_acc": @{
                                             @"info": @"compatible to non-SNI device",
                                             @"main": @[@"up.old_acc.main"]
                                             },
                                     @"old_src": @{
                                             @"info": @"compatible to non-SNI device",
                                             @"main": @[@"up.old_src.main"]
                                             },
                                     @"src": @{
                                             @"backup": @[
                                                     @"up.src.backup1",
                                                     @"up.src.backup2"
                                                     ],
                                             @"main": @[@"up.src.main"]
                                             }
                                     }
                             };
    [hosts addObject:main];
    [hosts addObject:backup];
    [resp setObject:hosts forKey:@"hosts"];
    return resp;
}

@end
