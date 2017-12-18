//
//  PLMediaViewerPKViewController.h
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 16/8/28.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLMediaUserPKType) {
    PLMediaUserPKTypeUnknown = 0,
    PLMediaUserPKTypeSecondChief = 1,
    PLMediaUserPKTypeViewer = 2
};

@interface PLMediaViewerPKViewController : UIViewController

@property (nonatomic, assign) PLMediaUserPKType userType;
@property (nonatomic, strong) NSString *roomName;

@end
