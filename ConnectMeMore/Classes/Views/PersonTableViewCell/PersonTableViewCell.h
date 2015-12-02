//
//  PersonTableViewCell.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 28/07/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NSDate+Utilities.h"

@interface PersonTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *personName;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *personPicture;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;


@end
