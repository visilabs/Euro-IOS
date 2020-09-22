//
//  EUROViewController.m
//  Euro-IOS
//
//  Created by egemen@visilabs.com on 12/09/2019.
//  Copyright (c) 2019 egemen@visilabs.com. All rights reserved.
//

#import "EUROViewController.h"
#import "EuroManager.h"

@interface EUROViewController ()

@end

@implementation EUROViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sync:(id)sender {
    [[EuroManager sharedManager:@"EuromsgIOSTest"] synchronize];
}

@end
