//
//  ProfileViewController.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 02/09/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)toggleSwitchControl:(id)sender;
- (IBAction)logOut:(id)sender;
@end
