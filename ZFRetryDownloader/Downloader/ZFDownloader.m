//
//  ZFDownloader.m
//  ZFRetryDownloader
//
//  Created by 钟凡 on 2019/2/22.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFDownloader.h"
#import "ZFTaskDelegate.h"

static dispatch_once_t onceToken;
static id instance;

@implementation ZFDownloader

+ (instancetype)shared {
    return [[ZFDownloader alloc] init];
}
- (instancetype)init {
    if (instance == nil) {
        dispatch_once(&onceToken, ^{
            instance = [super init];
        });
    }
    return instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (instance == nil) {
        dispatch_once(&onceToken, ^{
            instance = [super allocWithZone:zone];
        });
    }
    return instance;
}
-(void)downloadFileWithUrl:(NSString* _Nonnull)url savedPath:(NSString* _Nonnull)savedPath progress:(void (^_Nullable)(float progress))progressBlock success:(void (^ _Nullable )(NSURL * _Nonnull location))success failure:(void (^ _Nonnull )(NSError * _Nonnull error))failure {
    ZFTaskDelegate *delegate = [[ZFTaskDelegate alloc] init];
    delegate.recievedProgressBlock = progressBlock;
    delegate.downloadSuccessfulBlock = success;
    delegate.downloadFailedBlock = failure;
    delegate.savePath = savedPath;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:url]];
    [task resume];
}
- (void)retryDownloadFileWithUrls:(NSArray<NSString *> *)urls savedPath:(NSString* _Nonnull)savedPath progress:(void (^_Nullable)(float progress))progressBlock success:(void (^ _Nullable )(NSURL * _Nonnull location))successBlock failure:(void (^ _Nonnull )(NSError * _Nonnull error))failureBlock {
    __block BOOL shouldRetry = YES;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_async(dispatch_queue_create("com.zf.retryDownloadFileWithUrls", DISPATCH_QUEUE_SERIAL), ^{
        for (NSString *url in urls) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (shouldRetry == NO) {
                dispatch_semaphore_signal(semaphore);
                return;
            }
            [self downloadFileWithUrl:url savedPath:savedPath progress:^(float progress) {
                if (progressBlock) {
                    progressBlock(progress);
                }
            } success:^(NSURL * _Nonnull location) {
                shouldRetry = NO;
                dispatch_semaphore_signal(semaphore);
                if (successBlock) {
                    successBlock(location);
                }
            } failure:^(NSError * _Nonnull error) {
                dispatch_semaphore_signal(semaphore);
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        }
    });
}
@end
