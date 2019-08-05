//
//  HobbiesCollectionViewCell.h
//  DareLove
//
//  Created by Raobin on 2019/2/27.
//  Copyright © 2019 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HobbiesCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playMengView;
@property (weak, nonatomic) IBOutlet UILabel *playTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellNumLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectBtn;
@property (assign, nonatomic) BOOL status;
@end

NS_ASSUME_NONNULL_END
