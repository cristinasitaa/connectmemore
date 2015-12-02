//
//  Message.h
//  ConnectMeMore
//
//  Created by Adrian Ispas on 03/12/14.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef enum {
//    kMakeCall,
//    kEndCall,
//    kRejectCall
//} ActionType;

@interface Message : NSObject

@property (assign, nonatomic) NSString *actionType;
@property (strong, nonatomic) NSString *openTokSessionId;
@property (strong, nonatomic) NSString *openTokTokenId;

@end
