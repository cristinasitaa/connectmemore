//
//  LoginViewController.m
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/11/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "LoginViewController.h"
#import "UserManager.h"
#import "User.h"
#import "KeychainItemWrapper.h"
#import "BaseViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

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
    
    self.loginButton.enabled = NO;
    
    self.navigationController.navigationBarHidden = YES;
    
    int screenHeight = [[ UIScreen mainScreen ] bounds ].size.height;
    if (screenHeight == 568) // iphone 5
    {
        [self.scrollView removeObserver];
    } else {
        [self.scrollView addObserver];
    }
    
    if (self.navigationController){
        self.navigationController.navigationBarHidden = YES;
    }
    
    // Do any additional setup after loading the view from its nib.
    
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [SharedAppDelegate.callHeartbeatTimer invalidate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
    
}

- (void)textFieldDidChange:(NSNotification *)notification {
    // Do whatever you like to respond to text changes here.
    
    if (self.userNameTextField.text.length > 0 && self.passwordTextField.text.length > 0){
        self.loginButton.enabled = YES;
    } else {
        self.loginButton.enabled = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [self.userNameTextField setKeyboardType:UIKeyboardTypeEmailAddress];
    [self.userNameTextField becomeFirstResponder];
}


-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark TO DO: uncomment registerForRemoteNotificationTypes
- (IBAction)loginButtonPressed:(UIButton *)sender {
    
    // check for credentials
    if (!self.userNameTextField.text.length || !self.passwordTextField.text.length){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Email and password required." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        return;
    }

    if ([SharedAppDelegate.connected boolValue]){
        //login user
        User *user = [[User alloc] initWithEmail:self.userNameTextField.text andPassword:self.passwordTextField.text];
        [UserManager loginWithUser:user withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {
            if ([serializedObj[@"error"] boolValue] == YES || !serializedObj){
                NSLog(@"ERROR");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login" message:@"Invalid email or password" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            } else if (error == nil) {
                NSLog(@"SUCCESS");
                // save user email and password in keychain
                KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"CMM-Lateral-inc1" accessGroup:nil];
                [keychainItem setObject:self.passwordTextField.text forKey:(__bridge id)(kSecValueData)];
                [keychainItem setObject:self.userNameTextField.text forKey:(__bridge id)kSecAttrAccount];
            
                
                //show Persons View
                BaseViewController *baseController = [[BaseViewController alloc] init];
                baseController.modalPresentationStyle = UIModalTransitionStyleCrossDissolve;
                if (self.navigationController){
                    [self.navigationController presentViewController:baseController animated:NO completion:nil];
                } else {
                    UINavigationController *personsNav = [[UINavigationController alloc] initWithRootViewController:baseController];
                    SharedAppDelegate.window.rootViewController = personsNav;
                }
                
            }
            
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection error"
                                                        message:@"Missing connection to the internet"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
  
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.userNameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self.view endEditing:YES];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return YES;
}

- (IBAction)registerButtonPressed:(UIButton *)sender {
    
//    NSLog(@"Registering");
//    
//    // open Safari
//    NSURL *url = [NSURL URLWithString:kbaseURL];
//    
//    if (![[UIApplication sharedApplication] openURL:url]) {
//        NSLog(@"%@%@",@"Failed to open url:",[url description]);
//    }
    
}
@end
