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
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UISwitch *permissionSwitch;

@end

@implementation EUROViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _emailTextField.delegate = self;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];

    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sync:(id)sender {
    NSString* emailPermitValue = _permissionSwitch.on ? @"Y" : @"X";
    [[EuroManager sharedManager:@"EuromsgIOSTest"] addParams:@"emailPermit" value:emailPermitValue];
    [[EuroManager sharedManager:@"EuromsgIOSTest"] setUserEmail: _emailTextField.text];
    [[EuroManager sharedManager:@"EuromsgIOSTest"] synchronize];
}

- (IBAction)registerEmail:(id)sender {
    
    NSString* email = _emailTextField.text;
    BOOL emailPermit = _permissionSwitch.on;
    
    
    void (^success)(void) = ^void(void) {
        NSLog(@"registerEmail sucess");
    };
    
    void (^failure)(NSString*) = ^void(NSString* message) {
        NSLog(@"registerEmail failure");
        NSLog(@"%@", message);
    };
    
    [[EuroManager sharedManager:@"EuromsgIOSTest"] registerEmail:email emailPermit:emailPermit isCommercial:NO success:success failure:failure];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)dismissKeyboard
{
    [_emailTextField resignFirstResponder];
}

@end
