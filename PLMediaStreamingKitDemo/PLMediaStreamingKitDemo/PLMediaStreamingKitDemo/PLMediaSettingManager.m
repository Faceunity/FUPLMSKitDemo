//
//  PLMediaSettingManager.m
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 17/3/7.
//  Copyright © 2017年 Pili. All rights reserved.
//

#import "PLMediaSettingManager.h"

@implementation PLMediaSettingManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _roomName = nil;
        _onlyAudio = NO;
        _videoFrameRate = 24;
        _sessionPreset = AVCaptureSessionPreset640x480;
        _videoBitRate = 768000;
        _h264EncoderType = PLH264EncoderType_AVFoundation;
    }
    return self;
}

- (void)setObjValue:(PLMediaSettingManager *)settings {
    self.roomName = settings.roomName;
    self.onlyAudio = settings.onlyAudio;
    self.videoFrameRate = settings.videoFrameRate;
    self.sessionPreset = settings.sessionPreset;
    self.videoBitRate = settings.videoBitRate;
    self.h264EncoderType = settings.h264EncoderType;
}

- (BOOL)isEqualObj:(PLMediaSettingManager *)settings {
    if ( [self.roomName isEqualToString:settings.roomName] &&
        self.onlyAudio == settings.onlyAudio &&
        self.videoFrameRate == settings.videoFrameRate &&
        [self.sessionPreset isEqualToString:settings.sessionPreset] &&
        self.videoBitRate == settings.videoBitRate &&
        self.h264EncoderType == settings.h264EncoderType)
    {
        return YES;
    }
    else
        return NO;
}

@end
