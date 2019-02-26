//
//  ZFTaskDelegate.h
//  ZFRetryDownloader
//
//  Created by 钟凡 on 2019/2/25.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (copy, nonatomic) void(^recievedProgressBlock)(float progress);
@property (copy, nonatomic) void(^downloadSuccessfulBlock)(NSURL *location);
@property (copy, nonatomic) void(^downloadFailedBlock)(NSError *error);
@property (copy, nonatomic) NSString *savePath;

@end

NS_ASSUME_NONNULL_END
