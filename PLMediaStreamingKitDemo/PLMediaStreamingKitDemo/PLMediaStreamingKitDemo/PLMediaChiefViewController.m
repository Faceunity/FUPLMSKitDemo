//
//  PLMediaChiefViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by lawder on 16/6/30.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import "PLMediaChiefViewController.h"
#import "PLMediaStreamingKit.h"
#import "PLPlayerKit.h"
#import "PLMediaSettingManager.h"
#import "PLMediaSettingView.h"

#import <FUAPIDemoBar/FUAPIDemoBar.h>
#import "FUManager.h"

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

@interface PLMediaChiefViewController ()<PLMediaStreamingSessionDelegate, PLPlayerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, PLMediaSettingViewDelegate,

FUAPIDemoBarDelegate
>

@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UIButton *conferenceButton;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) PLMediaStreamingSession *session;

@property (nonatomic, assign) NSUInteger viewSpaceMask;

@property (nonatomic, strong) NSMutableDictionary *userViewDictionary;
@property (nonatomic, strong) NSString *    userID;
@property (nonatomic, strong) NSString *    roomToken;
@property (nonatomic, strong) PLStream *stream;

@property (nonatomic, strong) UIView *fullscreenView;
@property (nonatomic, strong) UIView *tappedView;
@property (nonatomic, assign) CGRect originRect;

@property (nonatomic, strong) UIButton *settingButton;
@property (nonatomic, strong) PLMediaSettingView *settingView;

@property (nonatomic, strong) NSURL *pushURL;


#pragma mark ---- FaceUnity
@property (nonatomic, strong) FUAPIDemoBar *demoBar ;

@end

@implementation PLMediaChiefViewController

#pragma mark ---- FaceUnity -----

- (void)addFaceUnityUI {
    
    UIButton *filterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    filterBtn.frame = CGRectMake(32, self.view.frame.size.height - 180, 55, 55) ;
    [filterBtn setImage:[UIImage imageNamed:@"camera_btn_filter_normal"] forState:UIControlStateNormal];
    [filterBtn addTarget:self action:@selector(showDemoBar:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:filterBtn];
    
    [self.view addSubview:self.demoBar];
}

/**
 Faceunity道具美颜工具条
 初始化 FUAPIDemoBar，设置初始美颜参数
 
 @param demoBar FUAPIDemoBar不是我们的交付内容，它的作用仅局限于我们的Demo演示，客户可以选择使用，但我们不会提供与之相关的技术支持或定制需求开发
 */
-(FUAPIDemoBar *)demoBar {
    
    if (!_demoBar) {
        _demoBar = [[FUAPIDemoBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 258, [UIScreen mainScreen].bounds.size.width, 208)];
        
        _demoBar.itemsDataSource = [FUManager shareManager].itemsDataSource;
        _demoBar.selectedItem = [FUManager shareManager].selectedItem;
        
        _demoBar.filtersDataSource = [FUManager shareManager].filtersDataSource;
        _demoBar.selectedFilter = [FUManager shareManager].selectedFilter;
        
        _demoBar.selectedBlur = [FUManager shareManager].selectedBlur;
        
        _demoBar.beautyLevel = [FUManager shareManager].beautyLevel;
        
        _demoBar.redLevel = [FUManager shareManager].redLevel;
        
        _demoBar.thinningLevel = [FUManager shareManager].thinningLevel;
        
        _demoBar.enlargingLevel = [FUManager shareManager].enlargingLevel;
        
        _demoBar.faceShapeLevel = [FUManager shareManager].faceShapeLevel;
        
        _demoBar.faceShape = [FUManager shareManager].faceShape;
        
        _demoBar.delegate = self ;
    }
    
    return _demoBar;
}

- (void)showDemoBar:(UIButton *)sender {
    
    [UIView animateWithDuration:0.4 animations:^{
        self.demoBar.frame = CGRectMake(0, self.view.frame.size.height - 258, [UIScreen mainScreen].bounds.size.width, 208) ;
    }];
    
    sender.selected = !sender.selected ;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [UIView animateWithDuration:0.4 animations:^{
        self.demoBar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 208);
    }];
}

- (void)demoBarDidSelectedItem:(NSString *)item {
    
    [[FUManager shareManager] loadItem:item];
}

- (void)demoBarDidSelectedFilter:(NSString *)filter {
    
    [FUManager shareManager].selectedFilter = filter;
}

- (void)demoBarBeautyParamChanged {
    
    [FUManager shareManager].selectedBlur = self.demoBar.selectedBlur;
    [FUManager shareManager].redLevel = self.demoBar.redLevel ;
    [FUManager shareManager].faceShapeLevel = self.demoBar.faceShapeLevel ;
    [FUManager shareManager].faceShape = self.demoBar.faceShape ;
    [FUManager shareManager].beautyLevel = self.demoBar.beautyLevel ;
    [FUManager shareManager].thinningLevel = self.demoBar.thinningLevel ;
    [FUManager shareManager].enlargingLevel = self.demoBar.enlargingLevel ;
}


-(void)dealloc {
    
    NSLog(@"PLMediaChiefViewController dealloc");
    /*-- 销毁道具 --*/
    [[FUManager shareManager] destoryItems];
}


#pragma mark - 视频数据回调

/// @abstract 获取到摄像头原数据时的回调, 便于开发者做滤镜等处理，需要注意的是这个回调在 camera 数据的输出线程，请不要做过于耗时的操作，否则可能会导致推流帧率下降
- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    //此处可以做美颜等处理
    [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
    
    return pixelBuffer;
}

#pragma mark ---- FaceUnity -----


#pragma mark - Managing the detail item

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES];
    self.userViewDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [self setupUI];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.roomName = [userDefaults objectForKey:@"PLMediaRoomName"];
    
    if (!self.roomName) {
        [self showAlertWithMessage:@"请先在设置界面设置您的房间名" completion:nil];
        return;
    }
    
    [self initStreamingSession];
    
    
    /**---- FaceUnity ----**/
    
    // FU 展示 UI
    [self addFaceUnityUI];
    
    // 加载 FU 默认初始值
    [[FUManager shareManager] loadItems];
    
    /**---- FaceUnity ----**/
}


- (void)setupUI
{
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 66, 66)];
    [self.backButton setTitle:@"返回" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(20, size.height - 66, 66, 66)];
    [self.actionButton setTitle:@"推流" forState:UIControlStateNormal];
    [self.actionButton setTitle:@"暂停" forState:UIControlStateSelected];
    [self.actionButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.actionButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.actionButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.actionButton addTarget:self action:@selector(actionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];
    self.actionButton.hidden = YES;
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width / 2 - 33, size.height - 66, 66, 66)];
    [self.muteButton setTitle:@"静音" forState:UIControlStateNormal];
    [self.muteButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.muteButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [self.muteButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.muteButton addTarget:self action:@selector(muteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteButton];
    
    self.conferenceButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 66 - 20, size.height - 66, 66, 66)];
    [self.conferenceButton setTitle:@"连麦" forState:UIControlStateNormal];
    [self.conferenceButton setTitle:@"停止" forState:UIControlStateSelected];
    [self.conferenceButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.conferenceButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.conferenceButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.conferenceButton addTarget:self action:@selector(conferenceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.conferenceButton];
    self.conferenceButton.hidden = YES;
    
    if (self.audioOnly) {
        self.view.backgroundColor = [UIColor blackColor];
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(20, 106, size.width, size.height - 106 * 2)];
        self.textView.editable = NO;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        [self.view addSubview:self.textView];
    }
    else {
        self.toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 66 - 20, 20, 66, 66)];
        [self.toggleButton setTitle:@"切换" forState:UIControlStateNormal];
        [self.toggleButton addTarget:self action:@selector(toggleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.toggleButton];
    }
    
    self.settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.settingButton.frame = CGRectMake(110, 20, 140, 66);
    [self.settingButton setTitle:@"推流／连麦设置" forState:UIControlStateNormal];
    [self.settingButton addTarget:self action:@selector(settingButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingButton];
    
    self.settingView = [[PLMediaSettingView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds))];
    self.settingView.delegte = self;
}

- (void)initStreamingSession
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.roomName = [userDefaults objectForKey:@"PLMediaRoomName"];
    
    
    /**---- FaceUnity ----**/
    self.roomName = @"pilitest019" ;
    
    
    self.audioOnly = self.settingView.settings.onlyAudio;

    if (self.audioOnly) {
        self.session = [[PLMediaStreamingSession alloc]
                        initWithVideoCaptureConfiguration:nil
                        audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration] videoStreamingConfiguration:nil audioStreamingConfiguration:[PLAudioStreamingConfiguration defaultConfiguration] stream:nil];
        self.session.captureDevicePosition = AVCaptureDevicePositionFront ;
    }
    else {
        NSInteger videoFrameRate = self.settingView.settings.videoFrameRate;
        NSInteger videoBitRate = self.settingView.settings.videoBitRate;
        PLH264EncoderType h264EncoderType = self.settingView.settings.h264EncoderType;
        NSString *sessionPreset = self.settingView.settings.sessionPreset;
        
        PLVideoStreamingConfiguration *videoStreamingConfiguration = [[PLVideoStreamingConfiguration alloc] initWithVideoSize:CGSizeMake(352, 640) expectedSourceVideoFrameRate:videoFrameRate videoMaxKeyframeInterval:72 averageVideoBitRate:videoBitRate videoProfileLevel:AVVideoProfileLevelH264HighAutoLevel videoEncoderType:h264EncoderType];
        
        PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
        videoCaptureConfiguration.sessionPreset = sessionPreset;
        videoCaptureConfiguration.videoFrameRate = videoFrameRate;
        
        self.session = [[PLMediaStreamingSession alloc]
                        initWithVideoCaptureConfiguration:videoCaptureConfiguration
                        audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration] videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:[PLAudioStreamingConfiguration defaultConfiguration] stream:nil];
        self.session.captureDevicePosition = AVCaptureDevicePositionFront ;
        
        UIImage *waterMark = [UIImage imageNamed:@"qiniu.png"];
        [self.session setWaterMarkWithImage:waterMark position:CGPointMake(100, 100)];
        self.session.previewView.frame = self.view.bounds;
        self.fullscreenView = self.session.previewView;
        [self addGestureOnView:self.fullscreenView];
        [self.view insertSubview:self.session.previewView atIndex:0];
        [self.session setBeautifyModeOn:NO];
    }
    
    self.session.delegate = self;
    
    self.actionButton.hidden = NO;
    self.conferenceButton.hidden = NO;

//    #您需要通过 App 的业务服务器去获取连麦需要的 userID 和 roomToken，此处为了 Demo 演示方便，可以在获取后直接设置下面这两个属性
    
    self.userID = @"<#userID#>";
    self.roomToken = @"<#roomToken#>";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- PLMediaSettingViewDelegate
- (void)mediaSettingView:(PLMediaSettingView *)mediaSettingView {
    [self.session stopConference];
    self.conferenceButton.selected = NO;
    self.conferenceButton.enabled = YES;
    self.actionButton.selected = NO;
    self.viewSpaceMask = 0;
    
    if (!self.audioOnly) {
        NSArray *remoteViews = [self.userViewDictionary allValues];
        for (UIView *view in remoteViews) {
            [view removeFromSuperview];
        }
        if (self.session.previewView.superview) {
            [self.session.previewView removeFromSuperview];
        }
    }
    
    self.session.delegate = nil;
    [self.session destroy];
    self.session = nil;
    
    [self initStreamingSession];
}

#pragma mark -- button clicked events
- (IBAction)backButtonClick:(id)sender
{    
    self.session.delegate = nil;
    [self.session destroy];
    self.session = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)settingButtonClick:(id)sender {
    [self.settingView show];
}

- (IBAction)toggleButtonClick:(id)sender
{
    [self.session toggleCamera];
    
    /**---- FaceUnity ----**/
    [[FUManager shareManager] onCameraChange];
}

- (IBAction)actionButtonClick:(id)sender
{
    if (!self.session.isStreamingRunning) {
        self.actionButton.enabled = NO;
        if (!self.session.stream) {
            self.session.stream = self.stream;
        }
        
        _session.pushURL = self.pushURL;
        
//        #您需要通过 App 的业务服务器去获取推流地址，此处为了 Demo 演示方便，可以直接写死推流地址
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
    NSLog(@"self.session.muted == %d",self.session.isMuted);
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
        PLRTCConferenceType conferenceType = self.audioOnly ? PLRTCConferenceTypeAudio : PLRTCConferenceTypeAudioAndVideo;
        PLRTCConfiguration *configuration = [[PLRTCConfiguration alloc] initWithVideoSize:PLRTCVideoSizePreset352x640 conferenceType:conferenceType];
        [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:configuration];
        NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
        self.session.rtcOption = option;
        self.session.rtcMinVideoBitrate= 100 * 1000;
        self.session.rtcMaxVideoBitrate= 300 * 1000;
        self.session.rtcMixOverlayRectArray = [NSArray arrayWithObjects:[NSValue valueWithCGRect:CGRectMake(244, 448, 108, 192)], [NSValue valueWithCGRect:CGRectMake(244, 256, 108, 192)], nil];
    }
    else {
        [self.session stopConference];
    }
    return;
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


#pragma mark - observer

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (self.session.isRtcRunning) {
        [self.session stopConference];
        self.conferenceButton.enabled = YES;
    }
}


#pragma mark - 大小窗口切换

// 加此手势是为了实现大小窗口切换的功能
- (void)addGestureOnView:(UIView *)view {
    UISwipeGestureRecognizer* recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(viewSwiped:)];
    recognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [view addGestureRecognizer:recognizer];
}

- (void)animationToFullscreenWithView:(UIView *)view {
    [UIView beginAnimations:@"FrameAni" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationStopped:)];
    [UIView setAnimationRepeatCount:1];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    view.frame = self.view.frame;
    [UIView commitAnimations];
}

- (void)animationStopped:(NSString *)aniID {
    self.fullscreenView.frame = self.originRect;
    [self setKickoutButtonHidden:NO onView:self.fullscreenView];
    [self.view sendSubviewToBack:self.tappedView];
    self.fullscreenView = self.tappedView;
}

- (void)viewSwiped:(UITapGestureRecognizer *)gestureRecognizer {
    self.tappedView = gestureRecognizer.view;
    if (CGSizeEqualToSize(self.tappedView.frame.size, self.view.frame.size)) {
        return;
    }
    
    self.originRect = self.tappedView.frame;
    [self setKickoutButtonHidden:YES onView:self.tappedView];
    [self animationToFullscreenWithView:self.tappedView];
}

- (void)setKickoutButtonHidden:(BOOL)hidden onView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            subview.hidden = hidden;
        }
    }
}

//
//#pragma mark - 视频数据回调
//
///// @abstract 获取到摄像头原数据时的回调, 便于开发者做滤镜等处理，需要注意的是这个回调在 camera 数据的输出线程，请不要做过于耗时的操作，否则可能会导致推流帧率下降
//- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    
//    //此处可以做美颜等处理
//    
//    return pixelBuffer;
//}


#pragma mark - 推流回调

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", streamStateNames[state]];
    NSLog(@"%@", log);
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didDisconnectWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.actionButton.selected = NO;
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
    self.textView.text = [NSString stringWithFormat:@"%@%@\n", self.textView.text, log];
    
    if (state == PLRTCStateConferenceStarted) {
        self.conferenceButton.selected = YES;
    } else {
        self.conferenceButton.selected = NO;
        self.viewSpaceMask = 0;
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
    NSInteger space = 0;
    if (!(self.viewSpaceMask & 0x01)) {
        self.viewSpaceMask |= 0x01;
        space = 1;
    }
    else if (!(self.viewSpaceMask & 0x02)) {
        self.viewSpaceMask |= 0x02;
        space = 2;
    }
    else {
        //超出 3 个连麦观众，不再显示。
        return;
    }
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = screenSize.width * 108 / 352.0;
    CGFloat height = screenSize.height * 192 / 640.0;
    remoteView.frame = CGRectMake(screenSize.width - width, screenSize.height - height * space, width, height);
    remoteView.clipsToBounds = YES;
    [self.view addSubview:remoteView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(width - 40, 0, 40, 40)];
    [button setTitle:@"踢出" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [button addTarget:self action:@selector(kickoutButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [remoteView addSubview:button];
    
    [self addGestureOnView:remoteView];
    
    [self.userViewDictionary setObject:remoteView forKey:userID];
    [self.view bringSubviewToFront:self.conferenceButton];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session userID:(NSString *)userID didDetachRemoteView:(UIView *)remoteView {
    //如果有做大小窗口切换，当被 Detach 的窗口是全屏窗口时，用 removedPoint 记录自己的预览的窗口的位置，然后把自己的预览的窗口切换成全屏窗口显示
    CGPoint removedPoint = CGPointZero;
    if (remoteView == self.fullscreenView) {
        removedPoint = self.session.previewView.center;
        self.fullscreenView = nil;
        self.tappedView = self.session.previewView;
        [self animationToFullscreenWithView:self.tappedView];
    }
    else {
        removedPoint = remoteView.center;
    }
    
    [remoteView removeFromSuperview];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat height = screenSize.height * 192 / 640.0;
    if (self.view.frame.size.height - removedPoint.y < height) {
        self.viewSpaceMask &= 0xFE;
    }
    else {
        self.viewSpaceMask &= 0xFD;
    }
    
    [self.userViewDictionary removeObjectForKey:userID];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didKickoutByUserID:(NSString *)userID {
    [self.session stopConference];
    [self showAlertWithMessage:@"您被主播踢出房间了！" completion:^{
        [self backButtonClick:nil];
    }];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didJoinConferenceOfUserID:(NSString *)userID {
    self.textView.text = [NSString stringWithFormat:@"%@userID: %@ didJoinConference\n", self.textView.text, userID];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didLeaveConferenceOfUserID:(NSString *)userID {
    self.textView.text = [NSString stringWithFormat:@"%@userID: %@ didLeaveConference\n", self.textView.text, userID];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session audioLocalInputLevel:(NSInteger)inputLevel localOutputLevel:(NSInteger)outputLevel otherRtcActiveStreams:(NSDictionary *)rtcActiveStreams
{
    NSLog(@"inputLevel = %ld\noutputLevel = %ld\nrtcActiveStreams = %@",(long)inputLevel,(long)outputLevel,rtcActiveStreams);
}



@end
