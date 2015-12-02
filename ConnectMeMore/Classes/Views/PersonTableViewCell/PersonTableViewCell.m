//
//  PersonTableViewCell.m
//  ConnectMeMore
//
//  Created by Cristina Sita on 28/07/2014.
//  Copyright (c) 2014 Lateral. All rights reserved.
//

#import "PersonTableViewCell.h"

@implementation PersonTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        UIView *xibView = [[[NSBundle mainBundle] loadNibNamed:@"PersonTableViewCell" owner:self options:nil] objectAtIndex:0];
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
