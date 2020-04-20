//
//  QNHttpManager.m
//  QiniuSDK
//
//  Created by bailong on 14/10/1.
//  Copyright (c) 2014年 Qiniu. All rights reserved.
//

#import "QNAsyncRun.h"
#import "QNConfiguration.h"
#import "QNHttpResponseInfo.h"
#import "QNSessionManager.h"
#import "QNUserAgent.h"
#import "QNSystemTool.h"
#import "QNUploadInfoReporter.h"

#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)

typedef void (^QNSessionComplete)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error, NSURLSessionTaskMetrics *metrics, uint64_t bytesSent, uint64_t bytesTotal);
@interface QNSessionDelegateHandler : NSObject <NSURLSessionDataDelegate>

@property (nonatomic, copy) QNInternalProgressBlock progressBlock;
@property (nonatomic, copy) QNCancelBlock cancelBlock;
@property (nonatomic, copy) QNSessionComplete completeBlock;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSURLSessionTaskMetrics *taskMetrics;

@end

@implementation QNSessionDelegateHandler
#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    _responseData = data;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    self.completeBlock(_responseData, task.response, error, _taskMetrics, task.countOfBytesSent, task.countOfBytesExpectedToSend);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)) {
    _taskMetrics = metrics;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

    if (_progressBlock) {
        _progressBlock(totalBytesSent, totalBytesExpectedToSend);
    }
    if (_cancelBlock && _cancelBlock()) {
        [task cancel];
    }
}

@end

@interface QNSessionManager ()
@property UInt32 timeout;
@property (nonatomic, strong) QNUrlConvert converter;
@property (nonatomic, strong) NSDictionary *proxyDict;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, strong) NSMutableArray *sessionArray;
@end

@implementation QNSessionManager

- (instancetype)initWithProxy:(NSDictionary *)proxyDict
                      timeout:(UInt32)timeout
                 urlConverter:(QNUrlConvert)converter {
    if (self = [super init]) {
        _delegateQueue = [[NSOperationQueue alloc] init];
        _timeout = timeout;
        _converter = converter;
        _sessionArray = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init {
    return [self initWithProxy:nil timeout:60 urlConverter:nil];
}

- (void)sendRequest:(NSMutableURLRequest *)request
     withIdentifier:(NSString *)identifier
  withCompleteBlock:(QNCompleteBlock)completeBlock
  withProgressBlock:(QNInternalProgressBlock)progressBlock
    withCancelBlock:(QNCancelBlock)cancelBlock
         withAccess:(NSString *)access {
    
    NSString *domain = request.URL.host;
    NSString *u = request.URL.absoluteString;
    NSURL *url = request.URL;
    if (_converter != nil) {
        url = [[NSURL alloc] initWithString:_converter(u)];
        request.URL = url;
        domain = url.host;
    }
    [request setTimeoutInterval:_timeout];
    [request setValue:[[QNUserAgent sharedInstance] getUserAgent:access] forHTTPHeaderField:@"User-Agent"];
    [request setValue:nil forHTTPHeaderField:@"Accept-Language"];
    
    QNSessionDelegateHandler *delegate = [[QNSessionDelegateHandler alloc] init];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.connectionProxyDictionary = _proxyDict ? _proxyDict : nil;
    __block NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:_delegateQueue];
    [_sessionArray addObject:@{@"identifier":identifier,@"session":session}];

    delegate.cancelBlock = cancelBlock;
    delegate.progressBlock = progressBlock ? progressBlock : ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    };
    delegate.completeBlock = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error, NSURLSessionTaskMetrics *metrics, uint64_t bytesSent, uint64_t bytesTotal) {
        [self finishSession:session];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        QNHttpResponseInfo *info = [QNHttpResponseInfo buildResponseInfoHost:domain response:httpResponse body:data error:nil metrics:metrics bytesSent:bytesSent bytesTotal:bytesTotal];
        completeBlock(info, [info getResponseBody]);
    };
    
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request];
    [uploadTask resume];
}

- (void)multipartPost:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
         withFileName:(NSString *)key
         withMimeType:(NSString *)mime
       withIdentifier:(NSString *)identifier
    withCompleteBlock:(QNCompleteBlock)completeBlock
    withProgressBlock:(QNInternalProgressBlock)progressBlock
      withCancelBlock:(QNCancelBlock)cancelBlock
           withAccess:(NSString *)access {
    NSURL *URL = [[NSURL alloc] initWithString:url];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    request.HTTPMethod = @"POST";
    NSString *boundary = @"werghnvt54wef654rjuhgb56trtg34tweuyrgf";
    request.allHTTPHeaderFields = @{
        @"Content-Type" : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
    };
    NSMutableData *postData = [[NSMutableData alloc] init];
    for (NSString *paramsKey in params) {
        NSString *pair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", boundary, paramsKey];
        [postData appendData:[pair dataUsingEncoding:NSUTF8StringEncoding]];

        id value = [params objectForKey:paramsKey];
        if ([value isKindOfClass:[NSString class]]) {
            [postData appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
        } else if ([value isKindOfClass:[NSData class]]) {
            [postData appendData:value];
        }
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSString *filePair = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\nContent-Type:%@\r\n\r\n", boundary, @"file", key, mime];
    [postData appendData:[filePair dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = postData;
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];

    [self sendRequest:request withIdentifier:identifier withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:cancelBlock
               withAccess:access];
}

- (void)post:(NSString *)url
             withData:(NSData *)data
           withParams:(NSDictionary *)params
          withHeaders:(NSDictionary *)headers
withIdentifier:(NSString *)identifier
    withCompleteBlock:(QNCompleteBlock)completeBlock
    withProgressBlock:(QNInternalProgressBlock)progressBlock
      withCancelBlock:(QNCancelBlock)cancelBlock
           withAccess:(NSString *)access {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:url]];
    if (headers) {
        [request setAllHTTPHeaderFields:headers];
    }
    [request setHTTPMethod:@"POST"];
    if (params) {
        [request setValuesForKeysWithDictionary:params];
    }
    [request setHTTPBody:data];
    QNAsyncRun(^{
        [self sendRequest:request
           withIdentifier:identifier
            withCompleteBlock:completeBlock
            withProgressBlock:progressBlock
              withCancelBlock:cancelBlock
                   withAccess:access];
    });
}

- (void)get:(NSString *)url
          withHeaders:(NSDictionary *)headers
    withCompleteBlock:(QNCompleteBlock)completeBlock {
    QNAsyncRun(^{
        NSURL *URL = [NSURL URLWithString:url];
        NSString *domain = URL.host;
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];

        QNSessionDelegateHandler *delegate = [[QNSessionDelegateHandler alloc] init];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        __block NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:self.delegateQueue];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
        delegate.cancelBlock = nil;
        delegate.progressBlock = nil;
        delegate.completeBlock = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error, NSURLSessionTaskMetrics *metrics, uint64_t bytesSent, uint64_t bytesTotal) {
            [self finishSession:session];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            QNHttpResponseInfo *info = [QNHttpResponseInfo buildResponseInfoHost:domain response:httpResponse body:data error:nil metrics:metrics bytesSent:bytesSent bytesTotal:bytesTotal];
            completeBlock(info, [info getResponseBody]);
        };
        [dataTask resume];
    });
}

- (void)finishSession:(NSURLSession *)session {
    for (int i = 0; i < _sessionArray.count; i++) {
        NSDictionary *sessionInfo = _sessionArray[i];
        if (sessionInfo[@"session"] == session) {
            [session finishTasksAndInvalidate];
            [_sessionArray removeObject:sessionInfo];
            break;
        }
    }
}

- (void)invalidateSessionWithIdentifier:(NSString *)identifier {
    
    for (int i = 0; i < _sessionArray.count; i++) {
        NSDictionary *sessionInfo = _sessionArray[i];
        if ([sessionInfo[@"identifier"] isEqualToString:identifier]) {
            NSURLSession *session = sessionInfo[@"session"];
            [session invalidateAndCancel];
            [_sessionArray removeObject:sessionInfo];
        }
    }
}

@end

#endif
