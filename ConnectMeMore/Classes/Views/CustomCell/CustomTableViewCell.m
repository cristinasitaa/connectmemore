//
//  CustomTableViewCell.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 20/08/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "CustomTableViewCell.h"

@implementation CustomTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        UIView *xibView = [[[NSBundle mainBundle] loadNibNamed:@"CustomTableViewCell" owner:self options:nil] objectAtIndex:0];
        [self.contentView setFrame:xibView.frame];
        [self.contentView addSubview:xibView];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
