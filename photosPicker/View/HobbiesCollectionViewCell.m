//
//  HobbiesCollectionViewCell.m
//  DareLove
//
//  Created by Raobin on 2019/2/27.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import "HobbiesCollectionViewCell.h"

@implementation HobbiesCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
  self.backgroundColor = [UIColor blackColor];
  [self.bgImageView setContentMode:UIViewContentModeScaleAspectFill];
  self.bgImageView.clipsToBounds = YES;
  self.selectImageView.layer.cornerRadius = 12.5f;
  self.selectImageView.layer.masksToBounds = YES;
}

@end
