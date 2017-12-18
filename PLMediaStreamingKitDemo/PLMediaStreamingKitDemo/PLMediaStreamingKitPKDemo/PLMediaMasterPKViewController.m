//
//  PLMediaMasterPKViewController.m
//  PLMediaStreamingKitDemo
//
//  Created by suntongmian on 16/8/28.
//  Copyright © 2016年 Pili. All rights reserved.
//

#import "PLMediaMasterPKViewController.h"
#import "PLMediaChiefPKViewController.h"
#import "PLMediaSettingPKViewController.h"
#import "PLMediaViewerPKViewController.h"
#import "PLPixelBufferProcessor.h"

@interface PLMediaMasterPKViewController ()

@property (nonatomic, strong) NSString *roomName;
@property NSArray *objects;

@end

@implementation PLMediaMasterPKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"PLMediaStreamingKitPKDemo";
    
    self.objects = @[@"主播", @"副主播", @"连麦观众"];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(settingButtonClick:)];
    self.navigationItem.rightBarButtonItem = item;
    
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)settingButtonClick:(id)sender
{
    PLMediaSettingPKViewController *settingViewController = [[PLMediaSettingPKViewController alloc] init];
    [self.navigationController pushViewController:settingViewController animated:YES];
}



#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.objects[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.roomName = [userDefaults objectForKey:@"PLMediaPKRoomName"];
    if (!self.roomName || [self.roomName isEqualToString:@""]) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"错误" message:@"请先在设置界面设置您的 roomID" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
        return;
    }
    
    if (indexPath.row == 0) {
        PLMediaChiefPKViewController *controller = [[PLMediaChiefPKViewController alloc] init];
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        controller.roomName = self.roomName;
        [self presentViewController:controller animated:YES completion:nil];
        
        return;
    }
    
    PLMediaViewerPKViewController *controller = [[PLMediaViewerPKViewController alloc] init];
    controller.userType = indexPath.row;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
    controller.roomName = self.roomName;
    [self presentViewController:controller animated:YES completion:nil];
}

@end
