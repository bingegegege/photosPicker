//
//  SJNotReachableControlLayer.h
//  SJVideoPlayer
//
//  Created by BlueDancer on 2019/1/15.
//  Copyright © 2019 畅三江. All rights reserved.
//

#import "SJEdgeControlLayerAdapters.h"
#import "SJControlLayerDefines.h"
@protocol SJNotReachableControlLayerDelegate;
@class SJButtonContainerView;

NS_ASSUME_NONNULL_BEGIN
extern SJEdgeControlButtonItemTag const SJNotReachableControlLayerTopItem_Back;


@interface SJNotReachableControlLayer : SJEdgeControlLayerAdapters<SJControlLayer>
@property (nonatomic, weak, nullable) id<SJNotReachableControlLayerDelegate> delegate;
@property (nonatomic, strong, readonly) UILabel *promptLabel;
@property (nonatomic, strong, readonly) SJButtonContainerView *reloadView;
@property (nonatomic) BOOL hideBackButtonWhenOrientationIsPortrait;
@end


@interface SJButtonContainerView : UIView
- (instancetype)initWithEdgeInsets:(UIEdgeInsets)insets;
@property (nonatomic) UIEdgeInsets insets;
@property (nonatomic, getter=isRoundedRect) BOOL roundedRect;
@property (nonatomic, strong, readonly) UIButton *button;
@end


@protocol SJNotReachableControlLayerDelegate <NSObject>
- (void)tappedBackButtonOnTheControlLayer:(id<SJControlLayer>)controlLayer;
- (void)tappedReloadButtonOnTheControlLayer:(id<SJControlLayer>)controlLayer;
@end
NS_ASSUME_NONNULL_END
