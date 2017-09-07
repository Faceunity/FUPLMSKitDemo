//
//  PLMediaViewerViewController.h
//  PLMediaStreamingKitDemo
//
//  Created by lawder on 16/6/30.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLMediaUserType) {
    PLMediaUserTypeUnknown = 0,
    PLMediaUserTypeSecondChief = 1,
    PLMediaUserTypeViewer = 2
};


@interface PLMediaViewerViewController : UIViewController

@property (nonatomic, assign) PLMediaUserType userType;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, assign) BOOL audioOnly;

@end

