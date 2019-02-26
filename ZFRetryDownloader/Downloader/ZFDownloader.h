//
//  ZFDownloader.h
//  ZFRetryDownloader
//
//  Created by 钟凡 on 2019/2/22.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFDownloader : NSObject

+(instancetype)shared;
-(void)downloadFileWithUrl:(NSString* _Nonnull)url savedPath:(NSString* _Nonnull)savedPath progress:(void (^_Nullable)(float progress))progressBlock success:(void (^ _Nullable )(NSURL * _Nonnull location))success failure:(void (^ _Nonnull )(NSError * _Nonnull error))failure;
- (void)retryDownloadFileWithUrls:(NSArray<NSString *> *)urls savedPath:(NSString* _Nonnull)savedPath progress:(void (^_Nullable)(float progress))progressBlock success:(void (^ _Nullable )(NSURL * _Nonnull location))successBlock failure:(void (^ _Nonnull )(NSError * _Nonnull error))failureBlock;

@end

NS_ASSUME_NONNULL_END
