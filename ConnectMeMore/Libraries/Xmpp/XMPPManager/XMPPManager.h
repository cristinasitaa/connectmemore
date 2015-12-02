//
//  BCXMPPManager.h
//  iPhoneXMPP
//
//  Created by Preduca Georgiana on 3/6/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "XMPPFramework.h"
#import "XMPPMUC.h"
#import "XMPPMessage.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "XMPPBlocking.h"
#import "XMPPUserCoreDataStorageObject.h"

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyPassword;


@interface XMPPManager : NSObject <XMPPRosterDelegate, XMPPMUCDelegate> {
    
    XMPPStream *xmppStream;
    XMPPStream *xmppStreamFB;
	XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
    XMPPMessageArchiving *xmppMessageArchiving;
    XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;
	XMPPCapabilities *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    XMPPRoomCoreDataStorage *xmppRoomCoreDataStorage;
    XMPPRoom *xmppRoom;
    XMPPRoomMemoryStorage *roomMemory;
    XMPPBlocking *xmppBlocking;
    XMPPMUC   *xmppMuc;
    GCDAsyncSocket *socketBG;
    
	NSString *password;
	
	BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
	
	BOOL isXmppConnected;
    
    XMPPMessage   *invitationMessage;
    XMPPPresence    *friendRequestPresence;
    
    BOOL isOnConversationScreen;
    BOOL firstForm;
    
    XMPPStream  *xmppStreamFb;
    
}


@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong, readonly) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong, readonly) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;
@property (nonatomic, strong, readonly) XMPPRoomCoreDataStorage *xmppRoomCoreDataStorage;
@property (nonatomic, strong, readonly) XMPPRoom *xmppRoom;
@property (nonatomic, strong, readonly) XMPPRoomMemoryStorage *roomMemory;
@property (nonatomic, strong, readonly) XMPPBlocking *xmppBlocking;
@property (nonatomic, strong, readonly) XMPPMUC *xmppMuc;
@property (nonatomic, strong, readonly) GCDAsyncSocket *socketBG;

+ (id)sharedInstance;
- (void)setupStream;
- (void)teardownStream;
- (void)goOnline;
- (void)goOffline;
- (XMPPUserCoreDataStorageObject *)userForJid:(XMPPJID *)jid;


- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

- (BOOL)connect;
- (void)disconnect;

- (void)sendMessage:(NSDictionary *)messageDict toUser:(User *)user;
@end

