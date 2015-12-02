//
//  CallViewController.m
//  ConnectMeMore
//
//  Created by Adi Ispas on 7/9/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "CallViewController.h"
#import "BaseViewController.h"
#import "UIButton+WebCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CallViewController ()

@end

// Change to NO to subscribe to streams other than your own.
static bool subscribeToSelf = NO;

//static double widgetHeight = 240;
//static double widgetWidth = 320;

@implementation CallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.navigationBarHidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkUnavailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kNetworkAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveStatus:) name:kDidReceiveCallStatus object:nil];
    
    if ([self.status isEqualToString:@"incoming"]){
        self.isReceiving = [NSNumber numberWithBool:YES];
    } else {
        self.isReceiving = [NSNumber numberWithBool:NO];
    }
    
    if (![self.isReceiving boolValue]) { // MAKE CALL
        [self connectToBroadcast];
        [self.receivingView setAlpha:0.0];
        self.topUserNameLabel.text = [NSString stringWithFormat:@"Calling %@",self.user.name];
        self.connectingLabel.hidden = NO;
        
//        [self.userImageView sd_setImageWithURL:[NSURL URLWithString:self.passedAvatar] placeholderImage:[UIImage imageNamed:@"contacts.png"]];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/profile/%@/avatar",kbaseURL,self.user.userID]];
        [self.userImageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"contacts.png"] options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {}];
    
    } else { // RECEIVE CALL
        
        [self.sendingView setAlpha:0.0];
        self.topUserNameLabel.text = [NSString stringWithFormat:@"%@ is calling",self.passedName];
        self.topUserNameLabel.adjustsFontSizeToFitWidth = YES;
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/profile/%@/avatar",kbaseURL,self.user.userID]];
        [self.callerImageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"contacts.png"] options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {}];
        
        self.connectingLabel.hidden = YES;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.endCallButton.layer.cornerRadius = 4.0;
    self.endCallButton.clipsToBounds = YES;
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configureAVAudioSession];
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.5];
    
    if (![self.isReceiving boolValue]){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Phone_Ringing"ofType:@"wav"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
        
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Vintage_Phone_Ringing"ofType:@"wav"];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
    }
    
    self.audioPlayer.numberOfLoops = -1;
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    
    [self.audioPlayer play];
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    SharedAppDelegate.inCall = YES;
    
//
//    [self configureAVAudioSession];
////    [[MPMusicPlayerController applicationMusicPlayer] setVolume:1.0];
//    
//    if (![self.isReceiving boolValue]){
//        NSString *path = [[NSBundle mainBundle] pathForResource: @"Phone_Ringing" ofType: @"wav"];
//        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
//        
//    } else {
//        NSString *path = [[NSBundle mainBundle] pathForResource: @"Vintage_Phone_Ringing" ofType: @"wav"];
//        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:NULL];
//    }
//    self.audioPlayer.delegate = self;
//    [self.audioPlayer prepareToPlay];
//    
//    [self.audioPlayer play];
//    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNetworkUnavailableNotification object:nil];
    SharedAppDelegate.inCall = NO;
}

- (void) configureAVAudioSession {
    //get your app's audioSession singleton object
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    
    //error handling
    BOOL success;
    NSError* error;
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    
    success = [session setCategory:AVAudioSessionCategoryPlayback
                             error:&error];
    
    if (!success)  NSLog(@"AVAudioSession error setting category:%@",error);
    
    //set the audioSession override
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                         error:&error];
    if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"AVAudioSession error activating: %@",error);
    else NSLog(@"audioSession active");
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.audioPlayer stop];
    self.audioPlayer.delegate = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
//    if (self.isLandscapeOK) {
//        // for iPhone, you could also return UIInterfaceOrientationMaskAllButUpsideDown
//        return UIInterfaceOrientationMaskAll;
//    }
    return UIInterfaceOrientationMaskAll;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
    [UIView animateWithDuration:0.5 animations:^{
        
    }];
    
    if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) {
        [UIView animateWithDuration:0.5 animations:^{
            if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
            {
                [_publisher.view setFrame:CGRectMake(700, 10, 300, 200)];
            } else {
                [_publisher.view setFrame:CGRectMake(400, 10, 150, 100)];
            }
        }];
        
        [UIView animateWithDuration:0.5 animations:^{
            [_subscriber.view setFrame:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
        }];
        
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
            {
                [_publisher.view setFrame:CGRectMake(700, 10, 300, 200)];
            } else {
                [_publisher.view setFrame:CGRectMake(150, 10, 150, 100)];
            }
        }];
        
        [UIView animateWithDuration:0.5 animations:^{
            [_subscriber.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        }];
    }
    
}

- (void)didReceiveStatus:(NSNotification *)notif {
    
    [UserManager dropCallForCallID:self.callID withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) { }];

    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    OTError *kError = nil;
    [self.session disconnect:&kError];
    [self cleanupPublisher];
    [self cleanupSubscriber];
    
    if (kError) {
        NSLog(@"disconnect failed with error: (%@)", kError);
    }
    cancelTimer = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Broadcast Methods
- (void)connectToBroadcast {
    
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    NSLog(@"connect to broadcast");
    
    // Create a new session when either there is no Session or the Session is old
    if (!self.session){
        self.session = [[OTSession alloc] initWithApiKey:kOpentokApiKey
                                               sessionId:SharedAppDelegate.sessionID
                                                delegate:self];
        
        //    }
        
        // Connect to the Session as long as its not already connecting or connected
        if ( !(self.session.sessionConnectionStatus == OTSessionConnectionStatusConnected ||
               self.session.sessionConnectionStatus == OTSessionConnectionStatusConnecting   ) ) {
            
            // Get a token and connect
            
            NSError *error;
            [self.session connectWithToken:SharedAppDelegate.deviceToken error:&error];
            if (error){
                NSLog(@"session error %@",error);
            }
        }
        [self changeUI];
    }
}

#pragma mark - OpenTok methods

/**
 * Asynchronously begins the session connect process. Some time later, we will
 * expect a delegate method to call us back with the results of this action.
 */
- (void)doConnect
{
    if (!self.connected){
        OTError *error;
        [self.session connectWithToken:SharedAppDelegate.deviceToken error:&error];
        if (error)
        {
            [self showAlert:[error localizedDescription]];
        }
    }
    
}

/**
 * Sets up an instance of OTPublisher to use with this session. OTPubilsher
 * binds to the device camera and microphone, and will provide A/V streams
 * to the OpenTok session.
 */
- (void)doPublish
{
    _publisher = [[Publisher alloc]
                  initWithDelegate:self
                  name:[[UIDevice currentDevice] name]];
    
    
    OTError *error;
    [self.session publish:_publisher error:&error];
    if (error)
    {
        [self.session disconnect:nil];
        [self connectToBroadcast];
    }
    
    
    [_publisher.view setFrame:self.ownerImageView.frame];
    
    [self.sendingView addSubview:_publisher.view];
    
    //Setup publisherView
    
    _publisher.view.layer.borderColor = [UIColor whiteColor].CGColor;
    _publisher.view.layer.borderWidth = 2.0;
    _publisher.view.layer.masksToBounds = YES;
    _publisher.view.layer.cornerRadius = 10.0;
    
}

/**
 * Cleans up the publisher and its view. At this point, the publisher should not
 * be attached to the session any more.
 */
- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
    // this is a good place to notify the end-user that publishing has stopped.
}

/**
 * Instantiates a subscriber for the given stream and asynchronously begins the
 * process to begin receiving A/V content for this stream. Unlike doPublish,
 * this method does not add the subscriber to the view hierarchy. Instead, we
 * add the subscriber only after it has connected and begins receiving data.
 */
- (void)doSubscribe:(OTStream*)stream
{
    _subscriber = [[Subscriber alloc] initWithStream:stream
                                            delegate:self];
    OTError *error;
    [self.session subscribe:_subscriber error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
    
}

/**
 * Cleans the subscriber from the view hierarchy, if any.
 * NB: You do *not* have to call unsubscribe in your controller in response to
 * a streamDestroyed event. Any subscribers (or the publisher) for a stream will
 * be automatically removed from the session during cleanup of the stream.
 */
- (void)cleanupSubscriber
{
    [_subscriber.view removeFromSuperview];
    _subscriber = nil;
}
# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    self.connected = YES;
    self.connectingLabel.hidden = YES;
    
    if (nil == _publisher) {
        [self doPublish];
    }

}


- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage = [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    _session = nil;
}

- (void)session:(OTSession*)mySession streamCreated:(OTStream *)stream
{
    
    [self.audioPlayer stop];
    self.audioPlayer.delegate = nil;
    NSLog(@"session streamCreated (%@)", stream.streamId);
    self.topUserNameLabel.text = self.user.name;
    
    // Step 3a: (if NO == subscribeToSelf): Begin subscribing to a stream we
    // have seen on the OpenTok session.
    if (nil == _subscriber && !subscribeToSelf) {
        [self doSubscribe:stream];
    }
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    
    [self endCallButtonPressed:nil];
    
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
    
    
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if ([_subscriber.stream.connection.connectionId
         isEqualToString:connection.connectionId])
    {
        [self cleanupSubscriber];
    }
    [self endCallButtonPressed:nil];
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

- (void)session:(OTSession *)session didReceiveStream:(OTStream *)stream
{
//    if (![self isBroadcastOwner]) {
        [self doSubscribe:stream];
//    }
}

- (void)session:(OTSession *)session didDropStream:(OTStream *)stream
{
    // Note: Removing subscriber view done automatically
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    
    [self.sendingView setAlpha:1.0];
    NSLog(@"subscriberDidConnectToStream (%@)",
          subscriber.stream.connection.connectionId);
    [_subscriber.view setFrame:self.callerImageView.frame];
    
    if (_publisher.stream.hasAudio) {
    }
    
    if (_publisher.stream.hasVideo) {
    }
    
    [self.sendingView insertSubview:_subscriber.view belowSubview:_publisher.view];
    [self.sendingView bringSubviewToFront:self.endCallButton];
    //    [self.view addSubview:_subscriber.view];
}

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@",
          subscriber.stream.streamId,
          error);
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream
{
    // Step 3b: (if YES == subscribeToSelf): Our own publisher is now visible to
    // all participants in the OpenTok session. We will attempt to subscribe to
    // our own stream. Expect to see a slight delay in the subscriber video and
    // an echo of the audio coming from the device microphone.
    if (nil == _subscriber && subscribeToSelf)
    {
        [self doSubscribe:stream];
    }
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream
{
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
    
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}


- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
	dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OTError"
                                                        message:string
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil] ;
        [alert show];
    });
}


- (IBAction)answerButtonPressed:(UIButton *)sender {
    
    [self.audioPlayer stop];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        [UserManager answerCallForCallID:self.callID withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {}];
//    });
    
    [self.receivingView setAlpha:0.0];
    [self.sendingView setAlpha:1.0];
    [self connectToBroadcast];

}

- (IBAction)declineButtonPressed:(UIButton *)sender {
    
    [self.audioPlayer stop];
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    messageDict[@"actionType"] = REJECTED_CALL;
    messageDict[@"openTokSessionId"] = SharedAppDelegate.sessionID;
    messageDict[@"openTokTokenId"] = SharedAppDelegate.deviceToken;
    
    [[XMPPManager sharedInstance] sendMessage:messageDict toUser:self.user];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    OTError *kError = nil;
    [self.session disconnect:&kError];
    [self cleanupPublisher];
    [self cleanupSubscriber];
    [UserManager dropCallForCallID:self.user.userID withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) {}];
    if (kError) {
        NSLog(@"disconnect failed with error: (%@)", kError);
    }
    
    
    cancelTimer = YES;
    
    //    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    [self endCallButtonPressed:nil];
}


- (IBAction)endCallButtonPressed:(UIButton *)sender {
    
    NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
    messageDict[@"actionType"] = END_CALL;
    messageDict[@"openTokSessionId"] = SharedAppDelegate.sessionID;
    messageDict[@"openTokTokenId"] = SharedAppDelegate.deviceToken;
    
    [[XMPPManager sharedInstance] sendMessage:messageDict toUser:self.user];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    OTError *kError = nil;
    [self.session disconnect:&kError];
    [self cleanupPublisher];
    [self cleanupSubscriber];
    [UserManager dropCallForCallID:self.callID withCompletitionBlock:^(id serializedObj, NSError *error, id returnedUser) { }];
    if (kError) {
        NSLog(@"disconnect failed with error: (%@)", kError);
    }
    
    
    cancelTimer = YES;
    
//    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)backButtonPressed:(id)sender {
    [self endCallButtonPressed:nil];
}

- (IBAction)optionsButtonPressed:(UIButton *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Audio", @"Video", @"Camera", nil];
    [actionSheet showInView:self.view];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0){
        //audio
        _publisher.publishAudio = !_publisher.publishAudio;
    }
    if (buttonIndex == 1) {
        //video
        _publisher.publishVideo = !_publisher.publishVideo;
    }
    if (buttonIndex == 2){
        //camera
        if (_publisher.cameraPosition == AVCaptureDevicePositionFront) {
            _publisher.cameraPosition = AVCaptureDevicePositionBack;
        } else {
            _publisher.cameraPosition = AVCaptureDevicePositionFront;
        }
        
    }
    
}







#pragma mark - UI

- (void) changeUI {
    
//    self.callerLabel.text = [NSString stringWithFormat:@"%@ is calling you.", self.connection[@"username"]];
    if ([self.isReceiving boolValue]) {
        // Initiate Call
//        self.callerLabel.text = self.connection[@"username"];
        
    } else {
        self.connectingLabel.hidden = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.session.streams.count == 0 && !cancelTimer) {
                NSLog(@"Missed Call");
                [self endCallButtonPressed:nil];
            }
        });
        
    }
    
}

#pragma mark - audio
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)data successfully:(BOOL)flag{
    
    [NSThread detachNewThreadSelector:@selector(playAudioAgain) toTarget:self withObject:nil];
    
}

- (void)playAudioAgain {
    
    [self.audioPlayer play];
}

- (void) networkStatusChanged:(NSNotification *)note {
    if (![SharedAppDelegate.connected boolValue]){
        [self endCallButtonPressed:nil];
    }
}

- (void)dealloc {
    
    [self cleanupPublisher];
    [self cleanupSubscriber];
    
    
    _callID = nil;
    _passedAvatar = nil;
    _passedName = nil;
    _status = nil;
    _isReceiving = nil;
    _audioPlayer = nil;
    _session = nil;
    _publisher = nil;
    _subscriber = nil;
    _timeoutTimer = nil;
    _topUserNameLabel = nil;
    _connectingLabel = nil;
    _sendingView = nil;
    _sendCallOptionsView = nil;
    _userImageView = nil;
    _ownerImageView = nil;
    _endCallButton = nil;
    _receivingView = nil;
    _callerLabel = nil;
    _answerButton = nil;
    _declineButton = nil;
    _callerImageView = nil;

}

@end
