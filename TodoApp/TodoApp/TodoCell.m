//
//  TodoCell.m
//  TodoApp
//
//  Created by Ruchi Varshney on 1/23/14.
//  Copyright (c) 2014 Ruchi Varshney. All rights reserved.
//

#import "TodoCell.h"

@implementation TodoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
