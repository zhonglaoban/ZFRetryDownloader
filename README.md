# ZFRetryDownloader

一个基于NSURLSession实现的下载模块，并封装了一个失败重试的逻辑。

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
+(instancetype)shared {
if (instance == nil) {
dispatch_once(&onceToken, ^{
instance = [super init];
});
}
return instance;
}
- (instancetype)init {
return [ZFDownloader shared];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
return [ZFDownloader shared];
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
```
接下来处理delegate中的事情，由于NSURLSessionDownloadDelegate只有下载完成、下载进度的回调，我们的代理还需要实现NSURLSessionDelegate的协议，来处理异常的情况。
#### 下载完成
下载完成后，文件默认存放在temp文件夹中，会被系统清除，所以我们需要把文件拷贝到其他目录中。
```Objective-c
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
NSFileManager *fileManager = [NSFileManager defaultManager];
NSURL *destUrl = [NSURL URLWithString:[self.savePath stringByAppendingPathComponent:location.lastPathComponent]];
if ([fileManager fileExistsAtPath:destUrl.absoluteString] == NO){
if (self.downloadFailedBlock) {
NSError *pathError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"目标路径不存在"}];
self.downloadFailedBlock(pathError);
}
}
NSError *fileMoveError;
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
#### 下载进度计算
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
当下载出错时会走didBecomeInvalidWithError这个方法，如果是系统性的错误，error不为空，如果是主动终止的任务，error为nil。
```Objective-c
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
NSError *failedError;
if (error) {
failedError = error;
}else {
failedError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"下载任务被用户终止"}];
}
if (self.downloadFailedBlock) {
self.downloadFailedBlock(failedError);
}
}
```
## Authors

* **zhonglaoban** - *Initial work* - [zhonglaoban](https://github.com/zhonglaoban)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
](# ZFRetryDownloader

一个基于NSURLSession实现的下载模块，并封装了一个失败重试的逻辑。

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
+(instancetype)shared {
    if (instance == nil) {
        dispatch_once(&onceToken, ^{
        instance = [super init];
        });
    }
    return instance;
}
- (instancetype)init {
    return [ZFDownloader shared];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZFDownloader shared];
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
```
接下来处理delegate中的事情，由于NSURLSessionDownloadDelegate只有下载完成、下载进度的回调，我们的代理还需要实现NSURLSessionDelegate的协议，来处理异常的情况。
#### 下载完成
下载完成后，文件默认存放在temp文件夹中，会被系统清除，所以我们需要把文件拷贝到其他目录中。
```Objective-c
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *destUrl = [NSURL URLWithString:[self.savePath stringByAppendingPathComponent:location.lastPathComponent]];
    if ([fileManager fileExistsAtPath:destUrl.absoluteString] == NO){
        if (self.downloadFailedBlock) {
            NSError *pathError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"目标路径不存在"}];
            self.downloadFailedBlock(pathError);
        }
    }
    NSError *fileMoveError;
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
#### 下载进度计算
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
当下载出错时会走didBecomeInvalidWithError这个方法，如果是系统性的错误，error不为空，如果是主动终止的任务，error为nil。
```Objective-c
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSError *failedError;
    if (error) {
        failedError = error;
    }else {
        failedError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"下载任务被用户终止"}];
    }
    if (self.downloadFailedBlock) {
        self.downloadFailedBlock(failedError);
    }
}
```
## Authors

* **zhonglaoban** - *Initial work* - [zhonglaoban](https://github.com/zhonglaoban)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
)](# ZFRetryDownloader

一个基于NSURLSession实现的下载模块，并封装了一个失败重试的逻辑。

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
+(instancetype)shared {
    if (instance == nil) {
        dispatch_once(&onceToken, ^{
        instance = [super init];
        });
    }
    return instance;
}
- (instancetype)init {
    return [ZFDownloader shared];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZFDownloader shared];
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
```
接下来处理delegate中的事情，由于NSURLSessionDownloadDelegate只有下载完成、下载进度的回调，我们的代理还需要实现NSURLSessionDelegate的协议，来处理异常的情况。
#### 下载完成
下载完成后，文件默认存放在temp文件夹中，会被系统清除，所以我们需要把文件拷贝到其他目录中。
```Objective-c
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *destUrl = [NSURL URLWithString:[self.savePath stringByAppendingPathComponent:location.lastPathComponent]];
    if ([fileManager fileExistsAtPath:destUrl.absoluteString] == NO){
        if (self.downloadFailedBlock) {
            NSError *pathError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"目标路径不存在"}];
            self.downloadFailedBlock(pathError);
        }
    }
    NSError *fileMoveError;
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
#### 下载进度计算
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
当下载出错时会走didBecomeInvalidWithError这个方法，如果是系统性的错误，error不为空，如果是主动终止的任务，error为nil。
```Objective-c
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSError *failedError;
    if (error) {
        failedError = error;
    }else {
        failedError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"下载任务被用户终止"}];
    }
    if (self.downloadFailedBlock) {
        self.downloadFailedBlock(failedError);
    }
}
```
## Authors

* **zhonglaoban** - *Initial work* - [zhonglaoban](https://github.com/zhonglaoban)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
)](# ZFRetryDownloader

一个基于NSURLSession实现的下载模块，并封装了一个失败重试的逻辑。

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
+(instancetype)shared {
    if (instance == nil) {
        dispatch_once(&onceToken, ^{
        instance = [super init];
        });
    }
    return instance;
}
- (instancetype)init {
    return [ZFDownloader shared];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZFDownloader shared];
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
```
接下来处理delegate中的事情，由于NSURLSessionDownloadDelegate只有下载完成、下载进度的回调，我们的代理还需要实现NSURLSessionDelegate的协议，来处理异常的情况。
#### 下载完成
下载完成后，文件默认存放在temp文件夹中，会被系统清除，所以我们需要把文件拷贝到其他目录中。
```Objective-c
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *destUrl = [NSURL URLWithString:[self.savePath stringByAppendingPathComponent:location.lastPathComponent]];
    if ([fileManager fileExistsAtPath:destUrl.absoluteString] == NO){
        if (self.downloadFailedBlock) {
            NSError *pathError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"目标路径不存在"}];
            self.downloadFailedBlock(pathError);
        }
    }
    NSError *fileMoveError;
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
#### 下载进度计算
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
当下载出错时会走didBecomeInvalidWithError这个方法，如果是系统性的错误，error不为空，如果是主动终止的任务，error为nil。
```Objective-c
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSError *failedError;
    if (error) {
        failedError = error;
    }else {
        failedError = [NSError errorWithDomain:NSCocoaErrorDomain code: -1 userInfo:@{NSLocalizedFailureReasonErrorKey: @"下载任务被用户终止"}];
    }
    if (self.downloadFailedBlock) {
        self.downloadFailedBlock(failedError);
    }
}
```
## Authors

* **zhonglaoban** - *Initial work* - [zhonglaoban](https://github.com/zhonglaoban)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
)