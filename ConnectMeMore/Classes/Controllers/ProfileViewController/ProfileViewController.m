//
//  ProfileViewController.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 02/09/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "ProfileViewController.h"
#import "KeychainItemWrapper.h"
#import "LoginViewController.h"
#import "UserManager.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.logOutButton.layer.cornerRadius = 2.0f;
    self.logOutButton.clipsToBounds = YES;
    if ([SharedAppDelegate.currentUser.status integerValue] == 1){
        [self.switchControl setOn:NO];
    }else{
        [self.switchControl setOn:YES];
    }
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *minorVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    self.versionLabel.text = [NSString stringWithFormat:@"Version: %@(%@)",majorVersion,minorVersion];
}

- (void)dealloc{
    _logOutButton = nil;
    _switchControl = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleSwitchControl:(id)sender {
    
    if (self.switchControl.on) {
        [UserManager setUserBusyWithCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
            if (!error){
                SharedAppDelegate.currentUser.status = [NSNumber numberWithInt:2];
                
            }
        }];
        [UserManager sendPresence:@"unavailable"];
        
    } else {
        [UserManager setUserAvailableWithCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
            if (!error){
                SharedAppDelegate.currentUser.status = [NSNumber numberWithInt:1];
                
            }
        }];
        [UserManager sendPresence:@"available"];
        
    }
}

- (IBAction)logOut:(id)sender {
    
    if (![SharedAppDelegate.connected boolValue]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"No Internet Connection. Try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Do you really want to log out?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alert show];
    

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kXMPPmyJID];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kXMPPmyPassword];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[XMPPManager sharedInstance] disconnect];
        
        // reset keychain
        KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"CMM-Lateral-inc1" accessGroup:nil];
        [keychainItem resetKeychainItem];
        
        //show Login view
        if (self.navigationController){
            LoginViewController *loginController = [[LoginViewController alloc] init];
            UINavigationController *loginNav = [[UINavigationController alloc] initWithRootViewController:loginController];
            [self.navigationController presentViewController:loginNav animated:NO completion:nil];
        }else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        SharedAppDelegate.currentUser = nil;
    }
}

@end
