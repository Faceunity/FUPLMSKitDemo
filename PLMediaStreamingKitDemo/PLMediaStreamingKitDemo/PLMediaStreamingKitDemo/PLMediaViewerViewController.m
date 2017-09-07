//
//  PLMediaViewerViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by lawder on 16/6/30.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import "PLMediaStreamingKit.h"
#import "PLPlayerKit.h"
#import "PLMediaViewerViewController.h"
#import "PLMediaSettingView.h"

#import <FUAPIDemoBar/FUAPIDemoBar.h>
#import "FUManager.h"

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

@interface PLMediaViewerViewController ()<PLMediaStreamingSessionDelegate, PLPlayerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, PLMediaSettingViewDelegate ,

FUAPIDemoBarDelegate
>

@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *conferenceButton;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *muteButton;

@property (nonatomic, strong) PLMediaStreamingSession *session;
@property (nonatomic, strong) PLPlayer *player;

@property (nonatomic, assign) NSUInteger viewSpaceMask;

@property (nonatomic, strong) NSMutableDictionary *userViewDictionary;
@property (nonatomic, strong) NSString *    userID;
@property (nonatomic, strong) NSString *    roomToken;

@property (nonatomic, assign) NSInteger reconnectCount;

@property (nonatomic, strong) UIView *fullscreenView;
@property (nonatomic, strong) UIView *tappedView;
@property (nonatomic, assign) CGRect originRect;

@property (nonatomic, strong) UIButton *settingButton;
@property (nonatomic, strong) PLMediaSettingView *settingView;


#pragma mark ---- FaceUnity
@property (nonatomic, strong) FUAPIDemoBar *demoBar ;
@end

@implementation PLMediaViewerViewController


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
    
    if (self.userType == PLMediaUserTypeSecondChief) {
        
        [UIView animateWithDuration:0.4 animations:^{
            self.demoBar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 208);
        }];
    }
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
    
    if (self.userType == PLMediaUserTypeSecondChief) {
        
        /*-- 销毁道具 --*/
        [[FUManager shareManager] destoryItems];
    }
}


/// @abstract 获取到摄像头原数据时的回调, 便于开发者做滤镜等处理，需要注意的是这个回调在 camera 数据的输出线程，请不要做过于耗时的操作，否则可能会导致推流帧率下降
- (CVPixelBufferRef)mediaStreamingSession:(PLMediaStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    if (self.userType == PLMediaUserTypeSecondChief) {
        
        //此处可以做美颜等处理
        [[FUManager shareManager] renderItemsToPixelBuffer:pixelBuffer];
    }
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
    self.reconnectCount = 0;
    
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
    [self initPlayer];
    
    
    
    if (self.userType == PLMediaUserTypeSecondChief) {
        
        /**---- FaceUnity ----**/
        
        // FU 展示 UI
        [self addFaceUnityUI];
        
        // 加载 FU 默认初始值
        [[FUManager shareManager] loadItems];
        
        /**---- FaceUnity ----**/
    }
}

- (void)setupUI
{
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 66, 66)];
    [self.backButton setTitle:@"返回" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    self.conferenceButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 66 - 20, size.height - 66, 66, 66)];
    [self.conferenceButton setTitle:@"连麦" forState:UIControlStateNormal];
    [self.conferenceButton setTitle:@"停止" forState:UIControlStateSelected];
    [self.conferenceButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.conferenceButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.conferenceButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.conferenceButton addTarget:self action:@selector(conferenceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.conferenceButton];
    self.conferenceButton.hidden = YES;
    
    self.muteButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width / 2 - 33, size.height - 66, 66, 66)];
    [self.muteButton setTitle:@"静音" forState:UIControlStateNormal];
    [self.muteButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.muteButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
    [self.muteButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.muteButton addTarget:self action:@selector(muteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteButton];
    
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
        self.toggleButton.hidden = YES;
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
    
    self.roomName = @"pilitest019" ;
    
    self.audioOnly = self.settingView.settings.onlyAudio;

    if (self.audioOnly) {
        self.session = [[PLMediaStreamingSession alloc]
                        initWithVideoCaptureConfiguration:nil
                        audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration] videoStreamingConfiguration:nil audioStreamingConfiguration:nil stream:nil];
        self.session.delegate = self;
        self.session.captureDevicePosition = AVCaptureDevicePositionFront ;
    }
    else {
        self.session = [[PLMediaStreamingSession alloc]
                        initWithVideoCaptureConfiguration:[PLVideoCaptureConfiguration defaultConfiguration]
                        audioCaptureConfiguration:[PLAudioCaptureConfiguration defaultConfiguration] videoStreamingConfiguration:nil audioStreamingConfiguration:nil stream:nil];
        self.session.delegate = self;
        self.session.previewView.frame = self.view.bounds;
        self.fullscreenView = self.session.previewView;
        [self addGestureOnView:self.fullscreenView];
        if (self.userType == PLMediaUserTypeSecondChief) {
            self.toggleButton.hidden = NO;
            [self.view insertSubview:self.session.previewView atIndex:0];
        }
        [self.session setBeautifyModeOn:NO];
        self.session.captureDevicePosition = AVCaptureDevicePositionFront ;
    }
    
    self.conferenceButton.hidden = NO;

//    #您需要通过 App 的业务服务器去获取连麦需要的 userID 和 roomToken，此处为了 Demo 演示方便，可以在获取后直接设置下面这两个属性
    
    self.userID = @"<#userID#>";
    self.roomToken = @"<#roomToken#>";
}

- (void)initPlayer
{
    if (self.userType == PLMediaUserTypeViewer) {
        PLPlayerOption *option = [PLPlayerOption defaultOption];
    
//        #您需要通过 App 的业务服务器去获取播放地址，此处为了 Demo 演示方便，可以直接写死播放地址
        self.player = [PLPlayer playerWithURL:[NSURL URLWithString:@"your playURL"] option:option];
        self.player.delegate = self;
        if (!self.audioOnly) {
            [self.view addSubview:self.player.playerView];
            [self.view sendSubviewToBack:self.player.playerView];
        }
        [self.player play];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- PLMediaSettingViewDelegate
- (void)mediaSettingView:(PLMediaSettingView *)mediaSettingView {
    [self resetSession];
}

- (void)resetSession {
    if (self.userType == PLMediaUserTypeSecondChief) {
        self.viewSpaceMask = 0;
        self.conferenceButton.selected = NO;
        self.conferenceButton.enabled = YES;
        self.muteButton.selected = NO;
        
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
        
        return;
    }
    
    if (self.userType == PLMediaUserTypeViewer) {
        self.viewSpaceMask = 0;
        self.conferenceButton.selected = NO;
        self.conferenceButton.enabled = YES;
        self.muteButton.selected = NO;
        
        if (!self.audioOnly) {
            NSArray *remoteViews = [self.userViewDictionary allValues];
            for (UIView *view in remoteViews) {
                [view removeFromSuperview];
            }
            self.toggleButton.hidden = YES;
            if (self.session.previewView.superview) {
                [self.session.previewView removeFromSuperview];
            }
            self.player.playerView.hidden = NO;
        }
        [self.player play];
        
        self.session.delegate = nil;
        [self.session destroy];
        self.session = nil;
        
        [self initStreamingSession];
        
        return;
    }
}

#pragma mark -- button clicked events
- (void)settingButtonClick:(id)sender {
    [self.settingView show];
}

- (void)kickoutByUserIDEvent:(id)sender {
    [self resetSession];
}

- (IBAction)backButtonClick:(id)sender
{
    self.session.delegate = nil;
    [self.session destroy];
    self.session = nil;
    
    self.player.delegate = nil;
    self.player = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

- (IBAction)toggleButtonClick:(id)sender
{
    [self.session toggleCamera];
    
    /**---- FaceUnity ----**/
    [[FUManager shareManager] onCameraChange];
}

- (IBAction)conferenceButtonClick:(id)sender
{
    self.conferenceButton.enabled = NO;
    if (self.userType == PLMediaUserTypeSecondChief) {
        if (!self.conferenceButton.selected) {
            PLRTCConferenceType conferenceType = self.audioOnly ? PLRTCConferenceTypeAudio : PLRTCConferenceTypeAudioAndVideo;
            PLRTCConfiguration *configuration = [[PLRTCConfiguration alloc] initWithVideoSize:PLRTCVideoSizePreset240x432 conferenceType:conferenceType];
            [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:configuration];
            NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
            self.session.rtcOption = option;
            self.session.rtcMinVideoBitrate= 300 * 1000;
            self.session.rtcMaxVideoBitrate= 800 * 1000;
        }
        else {
            [self.session stopConference];
        }
        
        return;
    }
    
    if (self.userType == PLMediaUserTypeViewer) {
        if (!self.conferenceButton.selected) {
            [self.player pause];
            
            if (!self.audioOnly) {
                self.player.playerView.hidden = YES;
                if (!self.session.previewView.superview) {
                    self.session.previewView.frame = self.view.bounds;
                    self.fullscreenView = self.session.previewView;
                    [self.view insertSubview:self.session.previewView atIndex:0];
                }
                self.toggleButton.hidden = NO;
            }
            
            PLRTCConferenceType conferenceType = self.audioOnly ? PLRTCConferenceTypeAudio : PLRTCConferenceTypeAudioAndVideo;
            PLRTCConfiguration *configuration = [[PLRTCConfiguration alloc] initWithVideoSize:PLRTCVideoSizePreset240x432 conferenceType:conferenceType];
            [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:configuration];
            NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
            self.session.rtcOption = option;
            self.session.rtcMinVideoBitrate= 300 * 1000;
            self.session.rtcMaxVideoBitrate= 800 * 1000;
        }
        else {
            [self.session stopConference];
            if (!self.audioOnly) {
                self.toggleButton.hidden = YES;
                if (self.session.previewView.superview) {
                    [self.session.previewView removeFromSuperview];
                }
                self.player.playerView.hidden = NO;
            }
            [self.player play];
        }
        
        return;
    }
}

- (IBAction)muteButtonClick:(id)sender
{
     if (self.session.isRtcRunning) {
        self.muteButton.selected = !self.muteButton.selected;
    }
    self.session.muted = self.muteButton.selected;
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

- (void)alertShow:(NSString *)message completion:(void (^)(void))completion
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"错误" message:message preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }]];
    [self presentViewController:controller animated:YES completion:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(dismissAlert:) userInfo:controller repeats:NO];
    
}

- (void)dismissAlert:(NSTimer *)timer{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        UIAlertView *alert = [timer userInfo];
        [alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:YES];
        alert = nil;
    } else {
        UIAlertController *alert = [timer userInfo];
        [alert dismissViewControllerAnimated:YES completion:nil];
        alert = nil;
    }
}

//- (void)dealloc
//{
//    NSLog(@"PLMediaViewerViewController dealloc");
//}

- (void)requestTokenWithUserID:(NSString *)userID completed:(void (^)(NSError *error, NSString *token))handler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://pili2-demo.qiniu.com/api/room/%@/user/%@/token", self.roomName, userID]];
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
        
        NSString *token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, token);
        });
    }];
    [task resume];
}

- (void)requestPlayUrlWithCompleted:(void (^)(NSError *error, NSString *playUrl))handler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://pili2-demo.qiniu.com/api/stream/%@/play", self.roomName]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 10;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(error, nil);
            });
            return;
        }
        
        NSString *url = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(nil, url);
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
    if (self.userType == PLMediaUserTypeSecondChief) {
        [self.session stopConference];
        return;
    }
    
    if (self.userType == PLMediaUserTypeViewer) {
        [self.session stopConference];
        if (!self.audioOnly) {
            self.toggleButton.hidden = YES;
            if (self.session.previewView.superview) {
                [self.session.previewView removeFromSuperview];
            }
            self.player.playerView.hidden = NO;
        }
        [self.player play];
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

#pragma mark - 连麦回调

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcStateDidChange:(PLRTCState)state {
    NSString *log = [NSString stringWithFormat:@"RTC State: %s", rtcStateNames[state]];
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@%@\n", self.textView.text, log];
    
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
    [self showAlertWithMessage:@"您被主播踢出房间了！" completion:^{
        [self kickoutByUserIDEvent:nil];
    }];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didJoinConferenceOfUserID:(NSString *)userID {
    self.textView.text = [NSString stringWithFormat:@"%@userID: %@ didJoinConference\n", self.textView.text, userID];
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session didLeaveConferenceOfUserID:(NSString *)userID {
    self.textView.text = [NSString stringWithFormat:@"%@userID: %@ didLeaveConference\n", self.textView.text, userID];
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
    [self alertShow:errorMessage completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * pow(2, self.reconnectCount) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
    });
}

- (void)mediaStreamingSession:(PLMediaStreamingSession *)session rtcMonitorAudioLocalInputLevel:(NSInteger)inputLevel localOutputLevel:(NSInteger)outputLevel otherRtcActiveStreams:(NSDictionary *)rtcActiveStreams
{
    NSLog(@"inputLevel = %ld",(long)inputLevel);
    NSLog(@"outputLevel = %ld",(long)outputLevel);
    NSLog(@"rtcActiveStreams = %@",rtcActiveStreams);
}


@end
