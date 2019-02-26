//
//  ZFTaskDelegate.m
//  ZFRetryDownloader
//
//  Created by 钟凡 on 2019/2/25.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ZFTaskDelegate.h"

@implementation ZFTaskDelegate

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.savePath] == NO){
        if (self.downloadFailedBlock) {
            NSError *pathError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"目标路径不存在"}];
            self.downloadFailedBlock(pathError);
        }
        return;
    }
    NSURL *destUrl = [NSURL fileURLWithPath:[self.savePath stringByAppendingPathComponent:downloadTask.response.suggestedFilename]];
    NSError *fileMoveError;
    if ([fileManager fileExistsAtPath:destUrl.path]){
        if (self.downloadSuccessfulBlock) {
            self.downloadSuccessfulBlock(destUrl);
        }
        return;
    }
    BOOL result = [fileManager moveItemAtURL:location toURL:destUrl error:&fileMoveError];
    if (result) {
        if (self.downloadSuccessfulBlock) {
            self.downloadSuccessfulBlock(destUrl);
        }
    }else {
        if (self.downloadFailedBlock) {
            self.downloadFailedBlock(fileMoveError);
        }
    }
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    if (self.recievedProgressBlock) {
        self.recievedProgressBlock(progress);
    }
}
#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        if (self.downloadFailedBlock) {
            self.downloadFailedBlock(error);
        }
    }
}
@end
