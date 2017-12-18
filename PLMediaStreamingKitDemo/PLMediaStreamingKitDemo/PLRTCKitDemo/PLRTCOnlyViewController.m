//
//  PLRTCOnlyViewController.m
//  PLRTCOnlyKitDemo
//
//  Created by lawder on 16/6/30.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import "PLRTCOnlyViewController.h"
#import "PLRTCSession.h"

const static char *rtcStateNames[] = {
    "Unknown",
    "ConferenceStarted",
    "ConferenceStopped"
};

@interface PLRTCOnlyViewController ()<PLRTCSessionStateDelegate>

@property (nonatomic, strong) UIButton *conferenceButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *toggleButton;

@property (nonatomic, strong) PLRTCSession *session;

@property (nonatomic, assign) NSUInteger viewSpaceMask;

@property (nonatomic, strong) NSString *    userID;
@property (nonatomic, strong) NSString *    roomToken;
@property (nonatomic, strong) NSString *roomName;

@property (nonatomic, strong) UIButton *settingButton;

@end

@implementation PLRTCOnlyViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.navigationController setNavigationBarHidden:YES];

    [self setupUI];
    [self initRTCSession];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}


- (void)setupUI
{
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 66, 66)];
    [self.backButton setTitle:@"返回" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    self.conferenceButton = [[UIButton alloc] initWithFrame:CGRectMake(20, size.height - 66, 66, 66)];
    [self.conferenceButton setTitle:@"连麦" forState:UIControlStateNormal];
    [self.conferenceButton setTitle:@"停止" forState:UIControlStateSelected];
    [self.conferenceButton.titleLabel setFont:[UIFont systemFontOfSize:22]];
    [self.conferenceButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.conferenceButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.conferenceButton addTarget:self action:@selector(conferenceButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.conferenceButton];
    
    self.audioButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width / 2 - 33, size.height - 66, 88, 66)];
    [self.audioButton setTitle:@"发布音频" forState:UIControlStateNormal];
    [self.audioButton setTitle:@"取消发布" forState:UIControlStateSelected];
    [self.audioButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.audioButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.audioButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.audioButton addTarget:self action:@selector(audioButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.audioButton];
    self.audioButton.enabled = NO;
    
    self.videoButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 88 - 20, size.height - 66, 88, 66)];
    [self.videoButton setTitle:@"发布视频" forState:UIControlStateNormal];
    [self.videoButton setTitle:@"取消发布" forState:UIControlStateSelected];
    [self.videoButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.videoButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [self.videoButton setTitleColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.1] forState:UIControlStateDisabled];
    [self.videoButton addTarget:self action:@selector(videoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.videoButton];
    self.videoButton.enabled = NO;

    self.toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width - 66 - 20, 20, 66, 66)];
    [self.toggleButton setTitle:@"切换" forState:UIControlStateNormal];
    [self.toggleButton addTarget:self action:@selector(toggleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];
}

- (void)initRTCSession
{
    PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
    PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
    self.session = [[PLRTCSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration];
                    
    UIImage *waterMark = [UIImage imageNamed:@"qiniu.png"];
    [self.session setWaterMarkWithImage:waterMark position:CGPointMake(100, 100)];
    self.session.previewView.frame = self.view.bounds;
    [self.view insertSubview:self.session.previewView atIndex:0];
    [self.session setBeautifyModeOn:YES];
    self.session.stateDelegate = self;
    
    ///开启摄像头采集后 previewView 才会有图像
    [self.session startVideoCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonClick:(id)sender
{
    self.session.stateDelegate = nil;
    [self.session destroy];
    self.session = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

- (IBAction)toggleButtonClick:(id)sender
{
    [self.session toggleCamera];
}

- (IBAction)conferenceButtonClick:(id)sender
{
    #warning 您需要通过 App 的业务服务器去获取连麦需要的 roomName、userID 和 roomToken，此处为了 Demo 演示方便，可以在手动获取后直接设置下面这三个属性
    self.roomName = @"your roomName";
    self.userID = @"your userID";
    self.roomToken = @"your roomToken";
    
    self.conferenceButton.enabled = NO;
    if (!self.conferenceButton.isSelected) {
        PLRTCConfiguration *configuration = [[PLRTCConfiguration alloc] initWithVideoSize:PLRTCVideoSizePreset352x640];
        [self.session startConferenceWithRoomName:self.roomName userID:self.userID roomToken:self.roomToken rtcConfiguration:configuration];
        NSDictionary *option = @{kPLRTCRejoinTimesKey:@(2), kPLRTCConnetTimeoutKey:@(3000)};
        self.session.rtcOption = option;
        self.session.rtcMinVideoBitrate= 100 * 1000;
        self.session.rtcMaxVideoBitrate= 300 * 1000;
    }
    else {
        [self.session stopConference];
    }
    return;
}

- (IBAction)audioButtonClick:(id)sender {
    if (self.session.state != PLRTCStateConferenceStarted) {
        return;
    }
    
    self.audioButton.enabled = NO;
    if (!self.audioButton.isSelected) {
        [self.session publishLocalAudioWithCompletionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.audioButton.enabled = YES;
                if (error) {
                    [self showAlertWithMessage:error.localizedDescription completion:nil];
                    return ;
                }
                
                ///发布音频成功后开启麦克风采集
                [self.session startAudioCapture];
                self.audioButton.selected = YES;
            });
        }];
    }
    else {
        [self.session unpublishLocalAudio];
        
        ///停止发布音频后停止麦克风采集
        [self.session stopAudioCapture];
        self.audioButton.selected = NO;
        self.audioButton.enabled = YES;
    }
}

- (IBAction)videoButtonClick:(id)sender {
    if (self.session.state != PLRTCStateConferenceStarted) {
        return;
    }
    
    self.videoButton.enabled = NO;
    if (!self.videoButton.isSelected) {
        [self.session publishLocalVideoWithCompletionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoButton.enabled = YES;
                if (error) {
                    [self showAlertWithMessage:error.localizedDescription completion:nil];
                    return ;
                }
                
                self.videoButton.selected = YES;
            });
        }];
    }
    else {
        [self.session unpublishLocalVideo];
        self.videoButton.selected = NO;
        self.videoButton.enabled = YES;
    }
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
    NSLog(@"PLRTCOnlyViewController dealloc");
}

#pragma mark - observer

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (self.session.isRunning) {
        [self.session stopConference];
        self.conferenceButton.enabled = YES;
    }
}

#pragma mark - 连麦回调

- (void)rtcSession:(PLRTCSession *)session stateDidChange:(PLRTCState)state {
    NSString *log = [NSString stringWithFormat:@"RTC State: %s", rtcStateNames[state]];
    NSLog(@"%@", log);
    
    if (state == PLRTCStateConferenceStarted) {
        self.conferenceButton.selected = YES;
        self.videoButton.enabled = YES;
        self.audioButton.enabled = YES;
        
    } else if (state == PLRTCStateConferenceStopped){
        self.conferenceButton.selected = NO;
        self.videoButton.enabled = NO;
        self.audioButton.enabled = NO;
        self.videoButton.selected = NO;
        self.audioButton.selected = NO;
        
        ///停止连麦后停止麦克风采集
        [self.session stopAudioCapture];
        self.viewSpaceMask = 0;
    }
    self.conferenceButton.enabled = YES;
}

/// @abstract 因产生了某个 error 的回调
- (void)rtcSession:(PLRTCSession *)session didFailWithError:(NSError *)error {
    NSLog(@"error: %@", error);
    self.conferenceButton.enabled = YES;
    [self showAlertWithMessage:[NSString stringWithFormat:@"Error code: %ld, %@", (long)error.code, error.localizedDescription] completion:^{
        [self backButtonClick:nil];
    }];
}

- (void)rtcSession:(PLRTCSession *)session userID:(NSString *)userID didAttachRemoteView:(UIView *)remoteView {
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
    [self.view bringSubviewToFront:self.videoButton];
}

- (void)rtcSession:(PLRTCSession *)session userID:(NSString *)userID didDetachRemoteView:(UIView *)remoteView {
    //如果有做大小窗口切换，当被 Detach 的窗口是全屏窗口时，用 removedPoint 记录自己的预览的窗口的位置，然后把自己的预览的窗口切换成全屏窗口显示
    CGPoint removedPoint = remoteView.center;
    [remoteView removeFromSuperview];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat height = screenSize.height * 192 / 640.0;
    if (self.view.frame.size.height - removedPoint.y < height) {
        self.viewSpaceMask &= 0xFE;
    }
    else {
        self.viewSpaceMask &= 0xFD;
    }
}

- (BOOL)rtcSession:(PLRTCSession *)session shouldSubscribeVideoOfUserID:(NSString *)userID {
    return YES;
}

- (void)rtcSession:(PLRTCSession *)session didJoinConferenceOfUserID:(NSString *)userID {
    NSLog(@"userID: %@ didJoinConference", userID);
}

- (void)rtcSession:(PLRTCSession *)session didLeaveConferenceOfUserID:(NSString *)userID {
    NSLog(@"userID: %@ didLeaveConference", userID);
}

- (void)rtcSession:(PLRTCSession *)session didpublishAudioOfUserID:(NSString *)userID {
    NSLog(@" userID: %@ didpublishAudio", userID);
}

- (void)rtcSession:(PLRTCSession *)session didUnpublishAudioOfUserID:(NSString *)userID {
    NSLog(@" userID: %@ didUnpublishAudio", userID);
}


@end
