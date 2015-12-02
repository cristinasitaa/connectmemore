//
//  BaseViewController.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 01/09/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "BaseViewController.h"
#import "MissedCallsViewController.h"
#import "ContactsViewController.h"
#import "ProfileViewController.h"
#import "UIColor+Hex.h"


@interface BaseViewController ()

@end

@implementation BaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"BaseViewController" bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    ContactsViewController *contactsVC = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil];
    [self addChildViewController:contactsVC];
    [self.containerView addSubview:contactsVC.view];
    self.currentChildViewController = contactsVC;
    UIImage *image = [UIImage imageNamed:@"Contacts 2.png"];
    if (image){
        [self.contactsButton setImage:image forState:UIControlStateNormal];
    }else{
        NSLog(@"no image");
    }
    [self.contactsButton setTitleColor:[UIColor colorFromHexString:@"01CBE0"] forState:UIControlStateNormal];
}



- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callReceived:) name:kShowCallVCNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kShowCallVCNotification object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - navigation
- (IBAction)showRecents:(id)sender {
    if ([self.currentChildViewController isKindOfClass:[MissedCallsViewController class]]){
        return;
    }
    
    [self.currentChildViewController removeFromParentViewController];
    [self.currentChildViewController.view removeFromSuperview];
    _currentChildViewController = nil;
    
    MissedCallsViewController *personsVC = [[MissedCallsViewController alloc] initWithNibName:@"MissedCallsViewController" bundle:nil];
    [self addChildViewController:personsVC];
    
    [self.containerView addSubview:personsVC.view];
    self.currentChildViewController = personsVC;
    
    [self.profileButton setImage:[UIImage imageNamed:@"Profil White.png"] forState:UIControlStateNormal];
    [self.profileButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.recentButton setImage:[UIImage imageNamed:@"recent 2.png"] forState:UIControlStateNormal];
     [self.recentButton setTitleColor:[UIColor colorFromHexString:@"01CBE0"] forState:UIControlStateNormal];
  
    [self.contactsButton setImage:[UIImage imageNamed:@"Contacts white.png"] forState:UIControlStateNormal];
    [self.contactsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

}

- (IBAction)showContacts:(id)sender {
    if ([self.currentChildViewController isKindOfClass:[ContactsViewController class]]){
        return;
    }
    [self.currentChildViewController removeFromParentViewController];
    [self.currentChildViewController.view removeFromSuperview];
    _currentChildViewController = nil;

    ContactsViewController *contactsVC = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:nil];
    
    if (self.passedMissedCall){
        contactsVC.passedMissedCall = self.passedMissedCall;
        self.passedMissedCall = nil;
    }
    
    [self addChildViewController:contactsVC];
    
    [self.containerView addSubview:contactsVC.view];
    self.currentChildViewController = contactsVC;
    
    [self.profileButton setImage:[UIImage imageNamed:@"Profil White.png"] forState:UIControlStateNormal];
    [self.profileButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.contactsButton setImage:[UIImage imageNamed:@"Contacts 2.png"] forState:UIControlStateNormal];
     [self.contactsButton setTitleColor:[UIColor colorFromHexString:@"01CBE0"] forState:UIControlStateNormal];
   
    [self.recentButton setImage:[UIImage imageNamed:@"Recent White.png"] forState:UIControlStateNormal];
    [self.recentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

}

- (IBAction)showProfile:(id)sender {
    if ([self.currentChildViewController isKindOfClass:[ProfileViewController class]]){
        return;
    }
    [self.currentChildViewController removeFromParentViewController];
    [self.currentChildViewController.view removeFromSuperview];
    _currentChildViewController = nil;

    ProfileViewController *profileVC = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController" bundle:nil];
    [self addChildViewController:profileVC];
    
    [self.containerView addSubview:profileVC.view];
    self.currentChildViewController = profileVC;
    
    [self.profileButton setImage:[UIImage imageNamed:@"Profil 2.png"] forState:UIControlStateNormal];
    [self.profileButton setTitleColor:[UIColor colorFromHexString:@"01CBE0"] forState:UIControlStateNormal];
    
    [self.contactsButton setImage:[UIImage imageNamed:@"Contacts white.png"] forState:UIControlStateNormal];
    [self.contactsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [self.recentButton setImage:[UIImage imageNamed:@"Recent White.png"] forState:UIControlStateNormal];
    [self.recentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

}



#pragma mark - call received
- (void)callReceived:(NSNotification *)note {
    User *user = [[User alloc] userFromXMPPUser:note.object];
    
    NSString *status = note.userInfo[@"status"];
    
    CallViewController *callController = [[CallViewController alloc] initWithNibName:@"CallViewController" bundle:nil];
    callController.user = user;
    callController.callID = note.userInfo[@"callID"];
    callController.passedName = user.name;
    callController.passedAvatar = user.avatarURL;
    callController.status = status;
    
    
    if (self.navigationController){
        [self.navigationController presentViewController:callController animated:NO completion:nil];
        [DejalActivityView removeView];
    } else {
        UINavigationController *callNav = [[UINavigationController alloc] initWithRootViewController:callController];
        [self presentViewController:callNav animated:NO completion:nil];
    }
    
}

- (void) dealloc{
    _recentButton = nil;
    _contactsButton = nil;
    _profileButton = nil;
    _buttonsView = nil;
    _containerView = nil;
    _passedMissedCall = nil;
    _currentChildViewController = nil;

}

@end
