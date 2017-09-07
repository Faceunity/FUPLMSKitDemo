//
//  PLMediaChiefPKViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 16/8/28.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import "PLMediaChiefPKViewController.h"
#import "PLMediaStreamingKit.h"
#import "PLPlayerKit.h"

const static char *streamStateNames[] = {
    "Unknow",
    "Connecting",
    "Connected",
    "Disconnecting",
    "Disconnected",
    "Error"
};

const static char *rtcStateNames[] = {
    "Unknown",
    "ConferenceStarted",
    "ConferenceStopped"
};

@interface PLMediaChiefPKViewController ()<PLMediaStreamingSessionDelegate, PLPlayerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIButton *conferenceButton;
@property (nonatomic, strong) UIButton *changeCameraStateButton; // 切换前置／后置摄像头

@property (nonatomic, strong) PLMediaStreamingSession *session;

@property (nonatomic, assign) NSUInteger viewSpaceMask;

@property (nonatomic, strong) NSMutableDictionary *userViewDictionary;
@property (nonatomic, strong) NSString *    userID;
@property (nonatomic, strong) NSString *    roomToken;
@property (nonatomic, strong) PLStream *stream;

@property (nonatomic, strong) NSURL *pushURL;

@end

@implementation PLMediaChiefPKViewController

#pragma mark - Managing the detail item


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.navigationController setNavigationBarHidden:YES];
    self.userViewDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    if (!self.roomName) {
        [self showAlertWithMessage:@"请先在设置界面设置您的房间名" completion:nil];
        return;
    }
    
    [self setupUI];
    [self initStreamingSession];
    
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
    
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 90, 66, 66)];
    [self.actionButton setTitle:@"推流" forState:UIControlStateNormal];
    [self.actionButton setTitle:@"暂停" forState:UIControlStateSelected];
    [self.actionButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.actionButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.actionButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.actionButton addTarget:self action:@selector(actionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];
    self.actionButton.hidden = YES;
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake(116, 90, 66, 66)];
    [self.muteButton setTitle:@"静音" forState:UIControlStateNormal];
    [self.muteButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.muteButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [self.muteButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.muteButton addTarget:self action:@selector(muteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteButton];
    
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
    [self.view addSubview:self.changeCameraStateButton];
}

- (void)initStreamingSession
{
    PLVideoStreamingConfiguration *videoStreamingConfiguration = [[PLVideoStreamingConfiguration alloc] initWithVideoSize:CGSizeMake(848, 480) expectedSourceVideoFrameRate:24 videoMaxKeyframeInterval:72 averageVideoBitRate:768 * 1024 videoProfileLevel:AVVideoProfileLevelH264HighAutoLevel videoEncoderType:PLH264EncoderType_AVFoundation];
    PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
    videoCaptureConfiguration.position = AVCaptureDevicePositionFront;
    videoCaptureConfiguration.sessionPreset = AVCaptureSessionPreset640x480;
    videoCaptureConfiguration.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    
    // 请保证 previewMirrorFrontFacing 与 streamMirrorFrontFacing 一致，previewMirrorRearFacing 与 streamMirrorRearFacing 来保证主播预览和推流的效果相同
    videoCaptureConfiguration.previewMirrorFrontFacing = YES;
    videoCaptureConfiguration.streamMirrorFrontFacing = YES;
    
    videoCaptureConfiguration.previewMirrorRearFacing = NO;
    videoCaptureConfiguration.streamMirrorRearFacing = NO;
    
    self.session = [[PLMediaStreamingSession alloc]
                    initWithVideoCaptureConfiguration:videoCaptureConfiguration
                    audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration]
                    videoStreamingConfiguration:videoStreamingConfiguration
                    audioStreamingConfiguration:[PLAudioStreamingConfiguration defaultConfiguration]
                    stream:nil];
    self.session.delegate = self;
    self.session.captureDevicePosition = videoCaptureConfiguration.position;
    self.session.fillMode = PLVideoFillModePreserveAspectRatioAndFill;
    UIImage *waterMark = [UIImage imageNamed:@"qiniu.png"];
    [self.session setWaterMarkWithImage:waterMark position:CGPointMake(0, 40)];
    [self.session setBeautifyModeOn:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        CGFloat width = screenSize.width;
        CGFloat height = screenSize.height;
        self.session.previewView.frame = CGRectMake(0, 0, width / 2.f, height);
        [self.view insertSubview:self.session.previewView atIndex:0];
    });
    
    
    self.actionButton.hidden = NO;
    self.conferenceButton.hidden = NO;

    #warning 您需要通过 App 的业务服务器去获取连麦需要的 userID 和 roomToken，此处为了 Demo 演示方便，可以在获取后直接设置下面这两个属性
    self.userID = @"your userID";
    self.roomToken = @"your roomToken";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonClick:(id)sender
{
    [self.session.previewView removeFromSuperview];
    
    self.session.delegate = nil;
    [self.session destroy];
    self.session = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (IBAction)actionButtonClick:(id)sender
{
    if (!self.session.isStreamingRunning) {
        self.actionButton.enabled = NO;
        if (!self.session.stream) {
            self.session.stream = self.stream;
        }
        
        _session.pushURL = self.pushURL;

        #warning 您需要通过 App 的业务服务器去获取推流地址，此处为了 Demo 演示方便，可以直接写死推流地址
        [self.session startStreamingWithPushURL:[NSURL URLWithString:@"your pushURL"] feedback:^(PLStreamStartStateFeedback feedback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionButton.enabled = YES;
                if (feedback == PLStreamStartStateSuccess) {
                    self.actionButton.selected = YES;
                }
                else {
                    [self showAlertWithMessage:[NSString stringWithFormat:@"推流失败! feedback is %lu", (unsigned long)feedback] completion:nil];
                }
            });
        }];
        
    } else {
        [self.session stopStreaming];
        self.actionButton.selected = NO;
    }
}

- (IBAction)muteButtonClick:(id)sender
{
    if (self.session.isRtcRunning) {
        self.muteButton.selected = !self.muteButton.selected;
    }
    self.session.muted = self.muteButton.selected;
}

- (void)kickoutButtonClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIView *view = button.superview;
    for (NSString *userID in self.userViewDictionary.allKeys) {
        if ([self.userViewDictionary objectForKey:userID] == view) {
            [self.session kickoutUserID:userID];
            break;
        }
    }
}

- (IBAction)conferenceButtonClick:(id)sender
{
    self.conferenceButton.enabled = NO;
    if (!self.conferenceButton.selected) {
        PLRTCConfiguration *configuration = [PLRTCConfiguration defaultConfiguration];
        configuration.mixVideoSize = CGSizeMake(848, 480);
        configuration.localVideoRect = CGRectMake(0, 0, 424, 480);
        [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:configuration];
        NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
        self.session.rtcOption = option;
        self.session.rtcMinVideoBitrate= 100 * 1000;
        self.session.rtcMaxVideoBitrate= 300 * 1000;
        
        // 连麦的画面在主画面中的位置和大小，连麦画面的宽高见 PLMediaViewerPKViewController.m 的 initStreamingSession 方法
        self.session.rtcMixOverlayRectArray = [NSArray arrayWithObjects:[NSValue valueWithCGRect:CGRectMake(424, 0, 424, 480)], nil];
    }
    else {
        [self.session stopConference];
    }
    return;
}

// 切换前置／后置摄像头
- (void)changeCameraStateButtonClick:(id)sender {
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
    NSLog(@"PLMediaChiefViewController dealloc");
}

- (void)requestStreamURLWithCompleted:(void (^)(NSError *error, NSString *urlString))handler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://pili2-demo.qiniu.com/api/stream/%@", self.roomName]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(error, nil);
            });
            return;
        }
        
        NSString *streamString = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, streamString);
        });
        
    }];
    [task resume];
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

#pragma mark - observer

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (self.session.isRtcRunning) {
        [self.session stopConference];
        self.conferenceButton.enabled = YES;
    }
}

#pragma mark - 推流回调

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", streamStateNames[state]];
    NSLog(@"%@", log);
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didDisconnectWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.actionButton.enabled = YES;
    [self showAlertWithMessage:[NSString stringWithFormat:@"Error code: %ld, %@", (long)error.code, error.localizedDescription] completion:nil];
}


/// @abstract 当开始推流时，会每间隔 3s 调用该回调方法来反馈该 3s 内的流状态，包括视频帧率、音频帧率、音视频总码率
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    NSLog(@"%@", status);
}

#pragma mark - 连麦回调

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcStateDidChange:(PLRTCState)state {
    NSString *log = [NSString stringWithFormat:@"RTC State: %s", rtcStateNames[state]];
    NSLog(@"%@", log);
    
    if (state == PLRTCStateConferenceStarted) {
        self.conferenceButton.selected = YES;
        self.actionButton.hidden = NO;
    } else {
        self.conferenceButton.selected = NO;
        self.actionButton.hidden = YES;
        self.viewSpaceMask = 0;
        [self.session stopStreaming];
    }
    self.conferenceButton.enabled = YES;
}

/// @abstract 因产生了某个 error 的回调
- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcDidFailWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.conferenceButton.enabled = YES;
    [self showAlertWithMessage:[NSString stringWithFormat:@"Error code: %ld, %@", (long)error.code, error.localizedDescription] completion:^{
        [self backButtonClick:nil];
    }];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session userID:(NSString *)userID didAttachRemoteView:(UIView *)remoteView {
    if (!(self.viewSpaceMask & 0x01)) {
        self.viewSpaceMask |= 0x01;
    } else {
        //超出 1 个连麦观众，不再显示。
        return;
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    remoteView.frame = CGRectMake(screenSize.width/2.f, 0, screenSize.width/2.f, screenSize.height);
    remoteView.clipsToBounds = YES;
    [self.view addSubview:remoteView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(screenSize.width * 0.4 - 40, 0, 40, 20)];
    [button setTitle:@"踢出" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [button addTarget:self action:@selector(kickoutButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [remoteView addSubview:button];
    
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
        [self backButtonClick:nil];
    }];
}

#pragma mark -- 限制控制器方向为 右横屏

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
