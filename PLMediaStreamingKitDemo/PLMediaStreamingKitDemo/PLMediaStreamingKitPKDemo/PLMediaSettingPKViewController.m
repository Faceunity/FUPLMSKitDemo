//
//  PLMediaSettingPKViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 16/8/28.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import "PLMediaSettingPKViewController.h"

@interface PLMediaSettingPKViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *roomTextField;
@property (weak, nonatomic) IBOutlet UILabel *versionNumLabel;

@end

@implementation PLMediaSettingPKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *roomName = [userDefaults objectForKey:@"PLMediaPKRoomName"];
    self.roomTextField.text = roomName;
    self.roomTextField.delegate = self;
    
    NSDictionary *info= [[NSBundle mainBundle] infoDictionary];
    self.versionNumLabel.text = [NSString stringWithFormat:@"版本：%@", info[@"CFBundleVersion"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ---- UITextField Delegate methods --------
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.roomTextField) {
        [self.roomTextField resignFirstResponder];
        [self saveButtonClickedEvent:nil];
    }
    
    return YES;
}

- (IBAction)saveButtonClickedEvent:(id)sender {
    if (!self.roomTextField.text  || [self.roomTextField.text isEqualToString:@""]) {
        [self showAlertWithMessage:@"房间名不能为空"];
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.roomTextField.text forKey:@"PLMediaPKRoomName"];
    [userDefaults synchronize];
    
    [self showAlertWithMessage:@"保存成功"];
}

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

@end
