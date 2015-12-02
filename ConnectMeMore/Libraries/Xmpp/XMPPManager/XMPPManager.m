//
//  BCXMPPManager.m
//  iPhoneXMPP
//
//  Created by Preduca Georgiana on 3/6/14.
//
//

#import "XMPPManager.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

static XMPPManager *kManager = nil;

@implementation XMPPManager

@synthesize roomMemory;
@synthesize xmppRoomCoreDataStorage;
@synthesize xmppRoom;
@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize xmppMessageArchiving;
@synthesize xmppMessageArchivingCoreDataStorage;
@synthesize xmppBlocking;
@synthesize xmppMuc;
@synthesize socketBG;


+ (id)sharedInstance {
    
    if (kManager == nil) {
        kManager = [[XMPPManager alloc] init];
    }
    return kManager;
}

- (void)dealloc
{
	[self teardownStream];
}

#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_Archiving {
    return [xmppMessageArchivingCoreDataStorage mainThreadManagedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//- (NSArray*)fetchMessages {
//    

//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    
//    NSManagedObjectContext *context = [self.xmppMessageArchivingCoreDataStorage mainThreadManagedObjectContext];
//    NSEntityDescription *messageEntity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:context];
//    
//    fetchRequest.entity = messageEntity;
//    
//    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
//    fetchRequest.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//    NSError *error = nil;
//    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    //Now you get the NSArray with element type of "XMPPMessageArchiving_Message_CoreDataObject"
    
//    return results;
//}

- (void)connectLogger {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}


- (void)setupStream
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[XMPPStream alloc] init];
//    [xmppStream setHostName:@"cmm.lateral-inc.com"];
    [xmppStream setHostName:xmppHostName];
//    xmppStream.autoStartTLS = YES;
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    
    xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:xmppMessageArchivingCoreDataStorage];
    [xmppMessageArchiving setClientSideMessageArchivingOnly:YES];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
    
    xmppMuc = [[XMPPMUC   alloc] init];
    
    xmppBlocking = [[XMPPBlocking alloc] init];
    xmppBlocking.autoRetrieveBlockingListItems = YES;

	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    xmppCapabilities.autoFetchMyServerCapabilities = YES;
    
    XMPPMessageDeliveryReceipts* xmppMessageDeliveryRecipts = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    xmppMessageDeliveryRecipts.autoSendMessageDeliveryReceipts = YES;
    xmppMessageDeliveryRecipts.autoSendMessageDeliveryRequests = YES;
    
    
    
	// Activate xmpp modules
    
	[xmppReconnect          activate:xmppStream];
	[xmppRoster             activate:xmppStream];
	[xmppvCardTempModule    activate:xmppStream];
	[xmppvCardAvatarModule  activate:xmppStream];
	[xmppCapabilities       activate:xmppStream];
    [xmppMessageArchiving   activate:xmppStream];
    [xmppRoom               activate:xmppStream];
    [xmppMuc                activate:xmppStream];
    [xmppBlocking           activate:xmppStream];
    [xmppMessageDeliveryRecipts activate:self.xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppMessageArchiving  addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppMuc addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppBlocking addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppCapabilities addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppMessageDeliveryRecipts addDelegate:self delegateQueue:dispatch_get_main_queue()];
    socketBG = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    
    

    
    
	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = YES;
	allowSSLHostNameMismatch = YES;
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// https://github.com/robbiehanson/XMPPFramework/wiki/WorkingWithElements

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    NSString *domain = [xmppStream.myJID domain];
    
    //Google set their presence priority to 24, so we do the same to be compatible.
    
    if([domain isEqualToString:@"gmail.com"]
       || [domain isEqualToString:@"gtalk.com"]
       || [domain isEqualToString:@"talk.google.com"])
    {
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        [presence addChild:priority];
    }
	
	[[self xmppStream] sendElement:presence];
    
//    [self disconnect];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
	if (![xmppStream isDisconnected]) {
		return YES;
	}
    
	NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
    
//        NSString *myJID = @"999@cmm.lateral-inc.com";
//    	NSString *myPassword = @"999";
    //
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    
	[xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
//    [xmppStream setMyJID:[XMPPJID jidWithString:myJID resource:RESOURCE]];
	password = myPassword;
    
	NSError *error = nil;
	if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}

    
	return YES;
}

- (void)disconnect
{
	[self goOffline];
	[xmppStream disconnect];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UIApplicationDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		NSString *expectedCertName = [xmppStream.myJID domain];
        
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
		DDLogError(@"Error authenticating: %@", error);
	}
    

    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self goOnline];

}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    
    NSLog(@"Did not authenticate");
//    
//    [xmppStream registerWithPassword:[[NSUserDefaults
//                                       standardUserDefaults] stringForKey:kXMPPmyPassword] error:nil];
//    
//    
//    NSError * err = nil;
//    
//    if(![[self xmppStream] registerWithPassword:password error:&err])
//    {
//        NSLog(@"Error registering: %@", err);
//    }

}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
    
    [iq addAttributeWithName:@"id" stringValue: [[[XMPPManager sharedInstance] xmppStream] generateUUID]];
    
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:register"];
    
    
    NSString *username = [[[[NSUserDefaults standardUserDefaults] valueForKeyPath:kXMPPmyJID] componentsSeparatedByString:@"@"]objectAtIndex:0];
    
    
    NSXMLElement *username1 = [NSXMLElement elementWithName:@"username" stringValue:username];
    [query addChild:username1];
    
    
    NSXMLElement *password1 = [NSXMLElement elementWithName:@"password" stringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"]];
    [query addChild:password1];
    
    [iq addChild:query];
    
    [[[XMPPManager sharedInstance] xmppStream] sendElement:iq];
    
    NSLog(@"%@", iq);
    
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement*)error {
    NSLog(@"Sorry the registration is failed"); 
    
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
  	return NO;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);


    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
                                                             xmppStream:xmppStream
                                                   managedObjectContext:[self managedObjectContext_roster]];
    
    if ([message.type isEqualToString:@"chat"]) {
        NSData *data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        NSLog(@"Message: %@",messageDict);
        
        if ([messageDict[@"actionType"] isEqualToString:MAKE_CALL]) {
        
            if (SharedAppDelegate.inCall) {
                
                User *newUser = [[User alloc] userFromXMPPUser:user];
                
                NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
                messageDict[@"actionType"] = REJECTED_CALL;
                messageDict[@"openTokSessionId"] = SharedAppDelegate.sessionID;
                messageDict[@"openTokTokenId"] = SharedAppDelegate.deviceToken;
                
                [self sendMessage:messageDict toUser:newUser];
            } else {
                SharedAppDelegate.sessionID = messageDict[@"openTokSessionId"];
                SharedAppDelegate.deviceToken = messageDict[@"openTokTokenId"];
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"name":user.nickname, @"callID":messageDict[@"callId"], @"status":@"incoming"}];
                [[NSNotificationCenter defaultCenter] postNotificationName:kShowCallVCNotification object:user userInfo:userInfo];
            }
            

        } else if ([messageDict[@"actionType"] isEqualToString:END_CALL]) {
                        
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveCallStatus object:user];
            
        } else if ([messageDict[@"actionType"] isEqualToString:REJECTED_CALL]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"The person you are calling is on another line" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveCallStatus object:user];
        }

    }
}

- (void)sendReadStatus:(XMPPMessage *)message {
    
    NSString *receivedId = [[[message elementForName:@"received" xmlns:@"urn:xmpp:receipts"] attributeForName:@"id"] stringValue];

    NSXMLElement *messagee = [NSXMLElement elementWithName:@"message"];
    
    NSXMLElement *read = [NSXMLElement elementWithName:@"read" xmlns:@"jabber:client"];

    [messagee addAttributeWithName:@"id" stringValue:receivedId];
    [messagee addAttributeWithName:@"to" stringValue:message.fromStr];
    
    [messagee addChild:read];
    
    [[[XMPPManager sharedInstance]xmppStream] sendElement:messagee];

}

- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitation:(XMPPMessage *)message {
    
}
- (void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *) roomJID didReceiveInvitationDecline:(XMPPMessage *)message {
    
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    
}


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}

- (XMPPUserCoreDataStorageObject *)userForJid:(XMPPJID *)jid {
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:jid
                                                             xmppStream:xmppStream
                                                   managedObjectContext:[self managedObjectContext_roster]];
    
    return user;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoomDidCreate:(XMPPRoom *)sender {
    NSLog(@"CREATE \n\n");
    
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender {
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"JOIN \n\n");

}

- (void)xmppCapabilities:(XMPPCapabilities *)sender didDiscoverCapabilities:(NSXMLElement *)caps forJID:(XMPPJID *)jid {
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm {
    
}

- (void)xmppBlocking:(XMPPBlocking *)sender didReceivedBlockingList:(NSArray*)blockingList {
    
    
    
}
- (void)xmppBlocking:(XMPPBlocking *)sender didNotReceivedBlockingListDueToError:(id)error {
    
}

- (void)xmppBlocking:(XMPPBlocking *)sender didBlockJID:(XMPPJID*)xmppJID {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppBlocking retrieveBlockingListItems];
}
- (void)xmppBlocking:(XMPPBlocking *)sender didNotBlockJID:(XMPPJID*)xmppJID error:(id)error {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppBlocking retrieveBlockingListItems];
}

- (void)xmppBlocking:(XMPPBlocking *)sender didUnblockJID:(XMPPJID*)xmppJID; {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppBlocking retrieveBlockingListItems];
}
- (void)xmppBlocking:(XMPPBlocking *)sender didNotUnblockJID:(XMPPJID*)xmppJID error:(id)error {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [xmppBlocking retrieveBlockingListItems];
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError {
    
}

- (void)sendMessage:(NSDictionary *)messageDict toUser:(User *)user {
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messageDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:jsonString];
    
    NSString *messageID = [[[XMPPManager sharedInstance]xmppStream]  generateUUID];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:user.jidStr];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addChild:body];
    
    [[[XMPPManager sharedInstance] xmppStream] sendElement:message];
}

- (void)xmppStream:(XMPPStream *)sender socketWillConnect:(GCDAsyncSocket *)socket
{
    // Tell the socket to stay around if the app goes to the background (only works on apps with the VoIP background flag set)
    [socket performBlock:^{
        [socket enableBackgroundingOnSocket];
    }];
}

@end
