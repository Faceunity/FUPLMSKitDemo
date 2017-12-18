//
//  PLMediaSettingView.h
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 17/3/14.
//  Copyright © 2017年 Pili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "PLMediaSettingManager.h"

@class PLMediaSettingView;
@protocol PLMediaSettingViewDelegate <NSObject>

- (void)mediaSettingView:(PLMediaSettingView *)mediaSettingView;

@end

@interface PLMediaSettingView : UIView

@property (nonatomic, weak) id<PLMediaSettingViewDelegate> delegte;
@property (nonatomic, strong) PLMediaSettingManager *settings;

- (void)show;

@end
