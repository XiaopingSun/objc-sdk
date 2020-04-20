//
//  QNBaseUpload.m
//  QiniuSDK
//
//  Created by WorkSpace_Sun on 2020/4/19.
//  Copyright © 2020 Qiniu. All rights reserved.
//

#import "QNBaseUpload.h"

@interface QNBaseUpload ()

@end

@implementation QNBaseUpload

- (void)run {
    // rewrite by subclass
}

- (void)collectHttpResponseInfo:(QNHttpResponseInfo *)httpResponseInfo fileOffset:(uint64_t)fileOffset {
    
    QNZonesInfo *zonesInfo = [self.config.zone getZonesInfoWithToken:self.token];
    NSString *targetRegionId = [zonesInfo getZoneInfoRegionNameWithType:QNZoneInfoTypeMain];
    NSString *currentRegionId = [zonesInfo getZoneInfoRegionNameWithType:self.currentZoneType];
    
    [Collector addRequestWithType:self.requestType httpResponseInfo:httpResponseInfo fileOffset:fileOffset targetRegionId:targetRegionId currentRegionId:currentRegionId identifier:self.identifier];
    if (self.requestType == QNRequestType_mkblk || self.requestType == QNRequestType_bput) {
        [Collector append:CK_blockBytesSent value:@(httpResponseInfo.bytesSent) identifier:self.identifier];
    }
    [Collector append:CK_totalBytesSent value:@(httpResponseInfo.bytesSent) identifier:self.identifier];
}

- (void)collectUploadQualityInfo {
    
    QNZonesInfo *zonesInfo = [self.config.zone getZonesInfoWithToken:self.token];
    NSString *targetRegionId = [zonesInfo getZoneInfoRegionNameWithType:QNZoneInfoTypeMain];
    NSString *currentRegionId = [zonesInfo getZoneInfoRegionNameWithType:self.currentZoneType];
    [Collector update:CK_targetRegionId value:targetRegionId identifier:self.identifier];
    [Collector update:CK_currentRegionId value:currentRegionId identifier:self.identifier];
    [Collector update:CK_fileSize value:@(self.size) identifier:self.identifier];
}
@end
