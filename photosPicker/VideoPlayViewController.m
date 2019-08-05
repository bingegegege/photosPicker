//
//  VideoPlayViewController.m
//  photosPicker
//
//  Created by 斌哥哥 on 2019/8/5.
//  Copyright © 2019 斌哥哥. All rights reserved.
//

#import "VideoPlayViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SJVideoPlayer.h"

@interface VideoPlayViewController ()
@property (nonatomic,strong)SJVideoPlayer *videoPlayer;//播放器对象
@end

@implementation VideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];;
    [self initUI];
}

-(void)initUI
{
    //网络视频路径
    NSString *webVideoPath = [NSString stringWithFormat:@"%@",_url];
    NSURL *webVideoUrl = [NSURL URLWithString:webVideoPath];
    _videoPlayer = [SJVideoPlayer player];
    _videoPlayer.view.frame = CGRectMake(0, 0, WIDTH, HEIGHT);
    [self.view addSubview:_videoPlayer.view];
    // 初始化资源
    _videoPlayer.URLAsset = [[SJVideoPlayerURLAsset alloc] initWithURL:webVideoUrl];
    __weak typeof(self) _self = self;
    _videoPlayer.playDidToEndExeBlock = ^(__kindof SJBaseVideoPlayer * _Nonnull player) {
        __strong typeof(_self) self = _self;
        if ( !self ) return ;
        [player replay];
    };
    
}

@end
