//
//  LoginViewController.h
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/11/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingScrollView.h"

@interface LoginViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonPressed:(UIButton *)sender;
- (IBAction)registerButtonPressed:(UIButton *)sender;
@end
