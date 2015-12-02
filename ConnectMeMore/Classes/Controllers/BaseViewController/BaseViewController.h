//
//  BaseViewController.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 01/09/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KeychainItemWrapper.h"
#import "MissedCall.h"

@interface BaseViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *recentButton;
@property (weak, nonatomic) IBOutlet UIButton *contactsButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet UIView *containerView;

@property (nonatomic, weak) UIViewController *currentChildViewController;
@property (strong, nonatomic) MissedCall *passedMissedCall;

- (IBAction)showRecents:(id)sender;
- (IBAction)showContacts:(id)sender;
- (IBAction)showProfile:(id)sender;


@end
