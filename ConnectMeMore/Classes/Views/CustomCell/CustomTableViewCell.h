//
//  CustomTableViewCell.h
//  ConnectMeMore
//
//  Created by Cristina Sita on 20/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *personPicture;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;

@end
