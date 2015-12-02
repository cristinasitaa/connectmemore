//
//  CallViewController.h
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>
#import "Publisher.h"
#import "Subscriber.h"
#import "UIImage+BlurredFrame.h"
#import "UIImage+ImageEffects.h"
#import "MissedCallsViewController.h"
#import "User.h"

@interface CallViewController : UIViewController <OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate, UIActionSheetDelegate, AVAudioPlayerDelegate> {
    OTSession * _session;
    Publisher * _publisher;
    Subscriber * _subscriber;
    BOOL cancelTimer;
}

@property (strong, nonatomic) User *user;

@property (retain, nonatomic) NSString *passedName;
@property (retain, nonatomic) NSString *passedAvatar;
@property (retain, nonatomic) NSString *callID;
@property (retain, nonatomic) NSString *status;

@property (retain, nonatomic) NSNumber *isReceiving;

@property (assign) BOOL connected;


@property (retain, nonatomic) OTSession *session;
@property (retain, nonatomic) Publisher *publisher;
@property (retain, nonatomic) Subscriber *subscriber;
@property (retain, nonatomic) NSTimer *timeoutTimer;


@property (weak, nonatomic) IBOutlet UILabel *topUserNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectingLabel;

//Sending Call
@property (weak, nonatomic) IBOutlet UIView *sendingView;
@property (weak, nonatomic) IBOutlet UIView *sendCallOptionsView;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UIImageView *ownerImageView;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;


//Incomming Call
@property (weak, nonatomic) IBOutlet UIView *receivingView;
@property (weak, nonatomic) IBOutlet UILabel *callerLabel;
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIImageView *callerImageView;

@property(nonatomic,strong)AVAudioPlayer *audioPlayer;

//IBActions
- (IBAction)answerButtonPressed:(UIButton *)sender;
- (IBAction)declineButtonPressed:(UIButton *)sender;
- (IBAction)endCallButtonPressed:(UIButton *)sender;
- (IBAction)backButtonPressed:(id)sender;

@end
