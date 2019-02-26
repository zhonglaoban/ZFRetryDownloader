# ZFRetryDownloader

一个基于NSURLSession实现的下载模块，并封装了一个下载失败重试的逻辑。

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

Xcode 9.0 or later; iOS 9.0 SDK or later

### Installing

首先从GitHub上克隆项目

```
git clone https://github.com/zhonglaoban/ZFRetryDownloader.git
```

然后打开ZFRetryDownloader.xcodeproj，就可以运行啦。

## Running the project

运行项目你会看到这个样子
<img src="https://github.com/zhonglaoban/ZFRetryDownloader/blob/master/Screenshots/screenshot1.png" width="200px" alt="截图1"/>
<img src="https://github.com/zhonglaoban/ZFRetryDownloader/blob/master/Screenshots/screenshot2.png" width="200px" alt="截图2"/>
- 图1:下载失败后无法显示图片
- 图2:下载失败会根据设置的数组重试或者下载其他资源

## Code Analysis

这个下载器是基于NSURLSession实现的，简单的说一下实现原理。

### 单例
在面向对象编程中，我们的下载器不需要频繁的创建和销毁，我们只需要管理好每一个下载的Task即可，所以我们用单例实现这个下载器。
注意：在oc中，init是初始化类的属性，alloc才是分配内存空间，所以我们需要对allocWithZone、init都做处理，确保是一个实例。
```Objective-c
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
```
我们创建一个task，然后开始下载。一个task就是一个下载任务，我们需要对不同的任务进行处理，所以我们创建一个ZFTaskDelegate类来处理这些下载任务。
```Objective-c
ZFTaskDelegate *delegate = [[ZFTaskDelegate alloc] init];

NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:url]];
[task resume];
```
将一些回调传递给delegate，通知调用者。
```Objective-c
delegate.recievedProgressBlock = progressBlock;
delegate.downloadSuccessfulBlock = success;
delegate.downloadFailedBlock = failure;
delegate.savePath = savedPath;
```
接下来处理delegate中的事情，由于NSURLSessionDownloadDelegate只有下载完成、下载进度的回调，我们的代理还需要实现NSURLSessionTaskDelegate的协议，来处理异常的情况。
#### 下载完成
下载完成后，文件默认存放在tmp文件夹中，会被系统清除，所以我们需要把文件拷贝到其他目录中。
```Objective-c
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
```
### 下载进度计算
下载进度计算是根据当前下载数据的大小比上下载数据的大小
```Objective-c
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    if (self.recievedProgressBlock) {
        self.recievedProgressBlock(progress);
    }
}
```
#### 错误处理
当下载出错时会走didCompleteWithError这个方法。
```Objective-c
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        if (self.downloadFailedBlock) {
            self.downloadFailedBlock(error);
        }
    }
}
```
### 下载重试逻辑
下载失败后我们希望自动重试，或者去下载其他资源，比如A->A->B、A->A->A->C等这样的逻辑。我的思路是把这些任务放在一个队列中，一次执行一个任务，如果有一个任务成功了，后面的就不执行了，这里我用的是GCD的信号量来控制的。
```Objective-c
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
```
## How to use
### 使用普通下载
```Objective-c
- (IBAction)normalDownload:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *savedPath = [paths objectAtIndex:0];
    [[ZFDownloader shared] downloadFileWithUrl:[self.retryUrls firstObject] savedPath:savedPath progress:^(float progress) {
        NSLog(@"%f", progress);
    } success:^(NSURL * _Nonnull location) {
        self.imageView.image = [UIImage imageWithContentsOfFile:location.path];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}
```
### 使用重试下载
```Objective-c
- (IBAction)retryDownload:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *savedPath = [paths objectAtIndex:0];
    [[ZFDownloader shared] retryDownloadFileWithUrls:self.retryUrls savedPath:savedPath progress:^(float progress) {
        NSLog(@"%f", progress);
    } success:^(NSURL * _Nonnull location) {
        self.imageView.image = [UIImage imageWithContentsOfFile:location.path];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}
```
[github地址](https://github.com/zhonglaoban/ZFRetryDownloader)
## Authors

* **zhonglaoban** - *Initial work* - [zhonglaoban](https://github.com/zhonglaoban)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
