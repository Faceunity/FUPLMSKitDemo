//
//  PLMediaSettingManager.h
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 17/3/7.
//  Copyright © 2017年 Pili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLTypeDefines.h"

@interface PLMediaSettingManager : NSObject

@property (strong, nonatomic) NSString *roomName;
@property (assign, nonatomic) BOOL onlyAudio;
@property (assign, nonatomic) NSInteger videoFrameRate;
@property (strong, nonatomic) NSString *sessionPreset;
@property (assign, nonatomic) NSInteger videoBitRate;
@property (assign, nonatomic) PLH264EncoderType h264EncoderType;

- (void)setObjValue:(PLMediaSettingManager *)settings;
- (BOOL)isEqualObj:(PLMediaSettingManager *)settings;

@end
