//
//  MissedCall.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 04/09/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MissedCall : NSObject

@property (strong, nonatomic) NSString *avatar;
@property (strong, nonatomic) NSString *duration;
@property (strong, nonatomic) NSString *missedCallID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *isOnline;
@property (strong, nonatomic) NSString *time;
@property (strong, nonatomic) NSString *type;

@end
