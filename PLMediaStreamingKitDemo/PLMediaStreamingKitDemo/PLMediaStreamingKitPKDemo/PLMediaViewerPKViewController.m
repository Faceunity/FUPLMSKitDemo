//
//  PLMediaViewerPKViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 16/8/28.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import "PLMediaViewerPKViewController.h"
#import "PLMediaStreamingKit.h"
#import "PLPlayerKit.h"
#import "PLPixelBufferProcessor.h"

const static char *rtcStateNames[] = {
    "Unknown",
    "ConferenceStarted",
    "ConferenceStopped"
};

const static NSString *playerStatusNames[] = {
    @"PLPlayerStatusUnknow",
    @"PLPlayerStatusPreparing",
    @"PLPlayerStatusReady",
    @"PLPlayerStatusCaching",
    @"PLPlayerStatusPlaying",
    @"PLPlayerStatusPaused",
    @"PLPlayerStatusStopped",
    @"PLPlayerStatusError"
};

@interface PLMediaViewerPKViewController ()<PLMediaStreamingSessionDelegate, PLPlayerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *conferenceButton;
@property (nonatomic, strong) UIButton *changeCameraStateButton; // 切换前置／后置摄像头

@property (nonatomic, strong) PLMediaStreamingSession *session;
@property (nonatomic, strong) PLPlayer *player;

@property (nonatomic, assign) NSUInteger viewSpaceMask;

@property (nonatomic, strong) NSMutableDictionary *userViewDictionary;
@property (nonatomic, strong) NSString *    userID;
@property (nonatomic, strong) NSString *    roomToken;

@property (nonatomic, assign) NSInteger reconnectCount;

@end

@implementation PLMediaViewerPKViewController

#pragma mark - Managing the detail item


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.navigationController setNavigationBarHidden:YES];
    self.userViewDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    self.reconnectCount = 0;
    
    if (!self.roomName) {
        [self showAlertWithMessage:@"请先在设置界面设置您的房间名" completion:nil];
        return;
    }
    
    [self setupUI];
    [self initStreamingSession];
    [self initPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)setupUI
{
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 44, 44)];
    [self.backButton setTitle:@"返回" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    self.conferenceButton = [[UIButton alloc] initWithFrame:CGRectMake(196, 90, 66, 66)];
    [self.conferenceButton setTitle:@"连麦" forState:UIControlStateNormal];
    [self.conferenceButton setTitle:@"停止" forState:UIControlStateSelected];
    [self.conferenceButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.conferenceButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.conferenceButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.conferenceButton addTarget:self action:@selector(conferenceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.conferenceButton];
    self.conferenceButton.hidden = YES;
    
    self.changeCameraStateButton = [[UIButton alloc] initWithFrame:CGRectMake(180, 20, 120, 44)];
    [self.changeCameraStateButton setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [self.changeCameraStateButton addTarget:self action:@selector(changeCameraStateButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    self.changeCameraStateButton.hidden = YES;
    [self.view addSubview:self.changeCameraStateButton];
}

- (void)initStreamingSession
{
    PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
    videoCaptureConfiguration.sessionPreset = AVCaptureSessionPreset640x480;
    videoCaptureConfiguration.position = AVCaptureDevicePositionFront;
    videoCaptureConfiguration.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    
    videoCaptureConfiguration.previewMirrorFrontFacing = YES;
    videoCaptureConfiguration.streamMirrorFrontFacing = YES;
    
    videoCaptureConfiguration.previewMirrorRearFacing = NO;
    videoCaptureConfiguration.streamMirrorRearFacing = NO;
    
    self.session = [[PLMediaStreamingSession alloc]
                    initWithVideoCaptureConfiguration:videoCaptureConfiguration
                    audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration]
                    videoStreamingConfiguration:nil
                    audioStreamingConfiguration:nil
                    stream:nil];
    self.session.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat width = screenSize.width;
        CGFloat height = screenSize.height;
        self.session.previewView.frame = CGRectMake(width / 2.f, 0, width / 2.f, height);
        self.session.fillMode = PLVideoFillModePreserveAspectRatioAndFill;
        if (self.userType == PLMediaUserPKTypeSecondChief) {
            self.changeCameraStateButton.hidden = NO;
            [self.view insertSubview:self.session.previewView atIndex:0];
        }
    });
    
    self.conferenceButton.hidden = NO;

    #warning 您需要通过 App 的业务服务器去获取连麦需要的 userID 和 roomToken，此处为了 Demo 演示方便，可以在获取后直接设置下面这两个属性
    self.userID = @"your userID";
    self.roomToken = @"your roomToken";
}

- (void)initPlayer
{
    if (self.userType == PLMediaUserPKTypeViewer) {
        PLPlayerOption *option = [PLPlayerOption defaultOption];
        
        #warning 您需要通过 App 的业务服务器去获取播放地址，此处为了 Demo 演示方便，可以直接写死播放地址
        self.player = [PLPlayer playerWithURL:[NSURL URLWithString:@"your playURL"] option:option];
        self.player.delegate = self;
        [self.view addSubview:self.player.playerView];
        [self.view sendSubviewToBack:self.player.playerView];
        [self.player play];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)kickoutByUserIDEvent:(id)sender {
    if (self.userType == PLMediaUserPKTypeSecondChief) {
        self.viewSpaceMask = 0;
        self.conferenceButton.selected = NO;
        self.conferenceButton.enabled = YES;
        
        NSArray *remoteViews = [self.userViewDictionary allValues];
        for (UIView *view in remoteViews) {
            [view removeFromSuperview];
        }
        
        if (self.session.previewView.superview) {
            [self.session.previewView removeFromSuperview];
        }
        self.session.delegate = nil;
        [self.session destroy];
        self.session = nil;
        
        [self initStreamingSession];
        
        return;
    }
    
    if (self.userType == PLMediaUserPKTypeViewer) {
        self.viewSpaceMask = 0;
        self.conferenceButton.selected = NO;
        self.conferenceButton.enabled = YES;
        
        NSArray *remoteViews = [self.userViewDictionary allValues];
        for (UIView *view in remoteViews) {
            [view removeFromSuperview];
        }
        self.changeCameraStateButton.hidden = YES;
        if (self.session.previewView.superview) {
            [self.session.previewView removeFromSuperview];
        }
        
        self.session.delegate = nil;
        [self.session destroy];
        self.session = nil;
        
        [self initStreamingSession];
        
        self.player.playerView.hidden = NO;
        [self.player play];
        
        return;
    }
}

- (IBAction)backButtonClick:(id)sender
{
    self.session.delegate = nil;
    [self.session destroy];
    self.session = nil;
    
    self.player.delegate = nil;
    self.player = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (IBAction)conferenceButtonClick:(id)sender
{
    self.conferenceButton.enabled = NO;
    if (self.userType == PLMediaUserPKTypeSecondChief) {
        if (!self.conferenceButton.selected) {
            [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:[PLRTCConfiguration defaultConfiguration]];
            NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
            self.session.rtcOption = option;
            self.session.rtcMinVideoBitrate= 300 * 1000;
            self.session.rtcMaxVideoBitrate= 800 * 1000;
        } else {
            [self.session stopConference];
        }
        
        return;
    }
    
    if (self.userType == PLMediaUserPKTypeViewer) {
        if (!self.conferenceButton.selected) {
            [self.player pause];
            self.player.playerView.hidden = YES;
            self.changeCameraStateButton.hidden = NO;
            if (!self.session.previewView.superview) {
                [self.view insertSubview:self.session.previewView atIndex:0];
            }
            
            [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:[PLRTCConfiguration defaultConfiguration]];
            NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
            self.session.rtcOption = option;
            self.session.rtcMinVideoBitrate= 300 * 1000;
            self.session.rtcMaxVideoBitrate= 800 * 1000;
        }
        else {
            [self.session stopConference];
            if (self.session.previewView.superview) {
                [self.session.previewView removeFromSuperview];
            }
            self.changeCameraStateButton.hidden = YES;
            self.player.playerView.hidden = NO;
            [self.player play];
        }
        
        return;
    }
}

// 切换前置／后置摄像头
- (IBAction)changeCameraStateButtonClick:(id)sender {
    [self.session toggleCamera];
}

- (void)showAlertWithMessage:(NSString *)message completion:(void (^)(void))completion
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"错误" message:message preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }]];
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)dealloc
{
    NSLog(@"PLMediaViewerViewController dealloc");
}

- (void)requestTokenWithUserID:(NSString *)userID completed:(void (^)(NSString *token))handler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://pili2-demo.qiniu.com/api/room/%@/user/%@/token", self.roomName, userID]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil || response == nil || data == nil) {
            NSLog(@"get token faild, %@, %@, %@", error, response, data);
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil);
            });
            return;
        }
        
        NSString *token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(token);
        });
    }];
    [task resume];
}

- (void)requestPlayUrlWithCompleted:(void (^)(NSString *playUrl))handler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://pili2-demo.qiniu.com/api/stream/%@/play", self.roomName]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 10;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil || response == nil || data == nil) {
            NSLog(@"get play url faild, %@, %@, %@", error, response, data);
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(nil);
            });
            return;
        }
        
        NSString *url = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(url);
        });
    }];
    [task resume];
}

#pragma mark - observer

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (!self.session.isRtcRunning) {
        return;
    }
    
    self.conferenceButton.enabled = YES;
    if (self.userType == PLMediaUserPKTypeSecondChief) {
        [self.session stopConference];
        return;
    }
    
    if (self.userType == PLMediaUserPKTypeViewer) {
        [self.session stopConference];
        self.changeCameraStateButton.hidden = YES;
        if (self.session.previewView.superview) {
            [self.session.previewView removeFromSuperview];
        }
        self.player.playerView.hidden = NO;
        [self.player play];
    }
}

#pragma mark - 连麦回调

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcStateDidChange:(PLRTCState)state {
    NSString *log = [NSString stringWithFormat:@"RTC State: %s", rtcStateNames[state]];
    NSLog(@"%@", log);
    
    if (state == PLRTCStateConferenceStarted) {
        self.conferenceButton.enabled = YES;
        self.conferenceButton.selected = YES;
    }
    else {
        self.conferenceButton.enabled = YES;
        self.conferenceButton.selected = NO;
        self.viewSpaceMask = 0;
    }
}

/// @abstract 因产生了某个 error 的回调
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcDidFailWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.conferenceButton.enabled = YES;
    self.conferenceButton.selected = NO;
    [self showAlertWithMessage:[NSString stringWithFormat:@"Error code: %ld, %@", (long)error.code, error.localizedDescription] completion:^{
        [self backButtonClick:nil];
    }];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session userID:(NSString *)userID didAttachRemoteView:(UIView *)remoteView {
    NSInteger space = 0;
    if (!(self.viewSpaceMask & 0x01)) {
        self.viewSpaceMask |= 0x01;
        space = 1;
    } else {
        //超出 1 个连麦观众，不再显示。
        return;
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    remoteView.frame = CGRectMake(0, 0, screenSize.width / 2, screenSize.height);
    [self.view insertSubview:remoteView belowSubview:self.session.previewView];
    
    remoteView.clipsToBounds = YES;
    
    [self.userViewDictionary setObject:remoteView forKey:userID];
    [self.view bringSubviewToFront:self.conferenceButton];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session userID:(NSString *)userID didDetachRemoteView:(UIView *)remoteView {
    if (![self.userViewDictionary objectForKey:userID]) {
        return;
    }
    [remoteView removeFromSuperview];
    [self.userViewDictionary removeObjectForKey:userID];
    self.viewSpaceMask = 0;
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didKickoutByUserID:(NSString *)userID {
    [self showAlertWithMessage:@"您被主播踢出房间了！" completion:^{
        [self kickoutByUserIDEvent:nil];
    }];
}

#pragma mark - <PLPlayerDelegate>

- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state {
    NSLog(@"%@", playerStatusNames[state]);
}

- (void)player:(nonnull PLPlayer *)player stoppedWithError:(nullable NSError *)error {
    NSLog(@"player error: %@", error);
    
    if (self.session.rtcState == PLRTCStateConferenceStarted) {
        return;
    }
    
    self.reconnectCount ++;
    NSString *errorMessage = [NSString stringWithFormat:@"Error code: %ld, %@, 播放器将在%.1f秒后进行第 %ld 次重连", (long)error.code, error.localizedDescription, 0.5 * pow(2, self.reconnectCount - 1), (long)self.reconnectCount];
    [self showAlertWithMessage:errorMessage completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * pow(2, self.reconnectCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
    });
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationLandscapeRight == toInterfaceOrientation) {
        self.session.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else {
        self.session.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskLandscapeLeft;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}

@end
