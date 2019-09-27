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
                                           @"main": @[@"1.io.src.main"]
                                           }
                                   },
                           @"up": @{
                                   @"acc": @{
                                           @"backup": @[
                                                   @"1.up.acc.backup1",
                                                   @"1.up.acc.backup2"
                                                   ],
                                           @"main": @[@"1.up.acc.main"]
                                           },
                                   @"old_acc": @{
                                           @"info": @"compatible to non-SNI device",
                                           @"main": @[@"1.up.old_acc.main"]
                                           },
                                   @"old_src": @{
                                           @"info": @"compatible to non-SNI device",
                                           @"main": @[@"1.up.old_src.main"]
                                           },
                                   @"src": @{
                                           @"backup": @[
                                                   @"1.up.src.backup1",
                                                   @"1.up.src.backup2"
                                                   ],
                                           @"main": @[@"1.up.src.main"]
                                           }
                                   }
                           };
    NSDictionary *backup = @{
                             @"ttl": @(86400),
                             @"io": @{
                                     @"src": @{
                                             @"main": @[@"2.io.src.main"]
                                             }
                                     },
                             @"up": @{
                                     @"acc": @{
                                             @"backup": @[
                                                     @"2.up.acc.backup1",
                                                     @"2.up.acc.backup2"
                                                     ],
                                             @"main": @[@"2.up.acc.main"]
                                             },
                                     @"old_acc": @{
                                             @"info": @"compatible to non-SNI device",
                                             @"main": @[@"2.up.old_acc.main"]
                                             },
                                     @"old_src": @{
                                             @"info": @"compatible to non-SNI device",
                                             @"main": @[@"2.up.old_src.main"]
                                             },
                                     @"src": @{
                                             @"backup": @[
                                                     @"2.up.src.backup1",
//                                                     @"up-z0.qiniup.com",
                                                     @"2.up.src.backup2"
                                                     ],
                                             @"main": @[@"2.up.src.main"]
                                             }
                                     }
                             };
    [hosts addObject:main];
    [hosts addObject:backup];
    [resp setObject:hosts forKey:@"hosts"];
    return resp;
}

@end
