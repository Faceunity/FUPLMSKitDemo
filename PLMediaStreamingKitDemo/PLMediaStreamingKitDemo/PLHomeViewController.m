//
//  MasterViewController.m
//  PLRTCStreamingKitDemo
//
//  Created by lawder on 16/6/30.
//  Copyright © 2016年 NULL. All rights reserved.
//

#import "PLHomeViewController.h"
#import "PLMediaMasterViewController.h"
#import "PLMediaMasterPKViewController.h"
#import "PLRTCOnlyViewController.h"

@interface PLHomeViewController ()

@property (nonatomic, strong) NSArray *objects;

@end

@implementation PLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"首页";
    self.objects = @[@"PLMediaStreamingKitDemo", @"PLMediaStreamingKitDemo(PK)", @"PLRTCKitDemo"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (indexPath.row == 0) {
        PLMediaMasterViewController *mediaViewController = [[PLMediaMasterViewController alloc] init];
        [self.navigationController pushViewController:mediaViewController animated:YES];
        return;
    }
    if (indexPath.row == 1) {
        PLMediaMasterPKViewController *mediaPKViewController = [[PLMediaMasterPKViewController alloc] init];
        [self.navigationController pushViewController:mediaPKViewController animated:YES];
        return;
    }
    if (indexPath.row == 2) {
        PLRTCOnlyViewController *viewController = [[PLRTCOnlyViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }
}




@end
