//
//  ViewController.m
//  ZFRetryDownloader
//
//  Created by 钟凡 on 2019/2/22.
//  Copyright © 2019 钟凡. All rights reserved.
//

#import "ViewController.h"
#import "ZFDownloader.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (copy, nonatomic) NSArray *retryUrls;
@end

@implementation ViewController
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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (NSArray *)retryUrls {
    if (_retryUrls == nil) {
        _retryUrls = @[
                       @"https://xxx.png",
                       @"https://www.erv-nsa.gov.tw/image/10579/1024x768",
                       @"https://www.erv-nsa.gov.tw/image/10577/1024x768"];
    }
    return _retryUrls;
}

@end
