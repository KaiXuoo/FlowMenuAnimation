//
//  BearAlertView.m
//  GOSHOPPING
//
//  Created by Bear on 16/6/26.
//  Copyright © 2016年 cjl. All rights reserved.
//

#import "BearAlertView.h"
#import <objc/runtime.h>
#import "BearAlertContentView.h"

static const char *const kAlertViewBlockKey   = "UDAlertViewBlockKey";

static NSString *kAnimationKey_ShowUDAlertView  = @"AnimationKey_ShowUDAlertView";
static NSString *kAnimationKey_CloseUDAlertView = @"AnimationKey_CloseUDAlertView";
static NSString *kAnimationKey_HideBgView       = @"AnimationKey_HideBgView";
static NSString *kAnimationKey_ShowBgView       = @"AnimationKey_ShowBgView";
static NSString *kAnimationKey_ShowUDAlertViewScale = @"AnimationKey_ShowUDAlertViewScale";


@interface BearAlertView () <UIApplicationDelegate>

@property (strong, nonatomic) UIView            *bgView;
@property (strong, nonatomic) UIView            *alertView;
@property (strong, nonatomic) UIView            *alertContentView;
@property (strong, nonatomic) BearAlertBtnsView *alertBtnsView;

@property (assign, nonatomic) AlertViewAnimation    alertViewAnimation;
@property (copy, nonatomic)   AnimationFinishBlock  animationFinishBlock;
@property (assign, nonatomic) AlertViewAnimationState alertViewAnimationState;

@end

@implementation BearAlertView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        _alertViewAnimation = kAlertViewAnimation_VerticalSpring;
        _tapBgCancel = YES;
        _layOutAndAutoShow = YES;
        
        [self createUI];
    }
    
    return self;
}

- (void)createUI
{
    self.frame = CGRectMake(0, 0, WIDTH, HEIGHT);
    
    //  背景蒙板View
    _bgView = [[UIView alloc] initWithFrame:self.bounds];
    _bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    [self addSubview:_bgView];
    
    //  触摸手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgTappedDismiss)];
    tapGesture.numberOfTapsRequired = 1;
    [_bgView addGestureRecognizer:tapGesture];
    
    //  AlertView
    _alertView = [[UIView alloc] init];
    _alertView.backgroundColor = [UIColor whiteColor];
    _alertView.layer.cornerRadius = 9.0f;
    _alertView.layer.masksToBounds = YES;
    [_bgView addSubview:_alertView];
    
    //  _contentView
    BearAlertContentView *alertContentView = [[BearAlertContentView alloc] init];
    alertContentView.titleLabel.text = @"请输入一个标题";
    alertContentView.contentLabel.text = @"请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!请输入正文内容!!!";
    
    //  _alertBtnsView
    BearAlertBtnsView *alertBtnsView = [[BearAlertBtnsView alloc] init];
    [alertBtnsView setNormal_CancelBtnTitle:@"取消" ConfirmBtnTitle:@"确认" ];
    
    //  设置AlertView组件
    [self setContentView:alertContentView];
    [self setBtnsView:alertBtnsView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [_alertContentView layoutSubviews];
    
    _alertBtnsView.frame = CGRectMake(0, _alertContentView.maxY, _alertContentView.width, 35);
    [_alertBtnsView layoutSubviews];
    
    _alertView.size = CGSizeMake(_alertContentView.width, _alertBtnsView.maxY);
    [_alertView BearSetCenterToParentViewWithAxis:kAXIS_X_Y];
    
    [_alertBtnsView.cancelBtn removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [_alertBtnsView.cancelBtn addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    [_alertBtnsView.confirmBtn removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [_alertBtnsView.confirmBtn addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    if (_layOutAndAutoShow == YES) {
        [self animationShow_udAlertView];
    }
}


#pragma mark - 设置AlertView组件

/**
 *  设置contentView
 */
- (void)setContentView:(UIView *)contentView
{
    if (_alertContentView) {
        [_alertContentView removeFromSuperview];
    }
    
    _alertContentView = contentView;
    [_alertView addSubview:_alertContentView];
}

/**
 *  设置btnsView
 */
- (void)setBtnsView:(BearAlertBtnsView *)btnsView
{
    if (_alertBtnsView) {
        [_alertBtnsView removeFromSuperview];
    }
    
    _alertBtnsView = btnsView;
    [_alertView addSubview:_alertBtnsView];
}



#pragma mark - 按钮处理事件

/**
 *  点击按钮block
 *
 *  @param confirmBlock 确认按钮block
 *  @param cancelBlock  取消按钮block
 */
- (void)alertView_ConfirmClickBlock:(kAlertViewBlock)confirmBlock CancelClickBlock:(kAlertViewBlock)cancelBlock
{
    objc_setAssociatedObject(_alertBtnsView.confirmBtn, kAlertViewBlockKey, confirmBlock, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(_alertBtnsView.cancelBtn, kAlertViewBlockKey, cancelBlock, OBJC_ASSOCIATION_RETAIN);
}

/**
 *  点击按钮block
 *
 *  @param selectBtn 点击的按钮
 *  @param block     按钮block
 */
- (void)alertView_SelectBtn:(UIButton *)selectBtn block:(kAlertViewBlock)block
{
    objc_setAssociatedObject(selectBtn, kAlertViewBlockKey, block, OBJC_ASSOCIATION_RETAIN);
}

/**
 *  添加按钮点击事件
 */
- (void)btnEvent:(UIButton *)sender
{
    [self animationClose_udAlertView];
    
    kAlertViewBlock block = objc_getAssociatedObject(sender, kAlertViewBlockKey);
    
    self.animationFinishBlock = ^{
        if (block) {
            block();
        }
    };
}

/**
 *  触摸消失
 */
- (void)bgTappedDismiss
{
    if (_tapBgCancel) {
        [self animationClose_udAlertView];
    }
}



#pragma mark - 动画处理

/**
 *  Alertview显现动画
 */
- (void)animationShow_udAlertView
{
    
    if (_alertViewAnimationState == kAlertViewAnimationState_Process) {
        return;
    }
    
    _alertViewAnimationState = kAlertViewAnimationState_Process;
    
    CGFloat animationTime_bgAlpha = 0.3;
    CGFloat animationTime_keyShow = 0.5;
    
    
    //  背景透明度
    CABasicAnimation *basicAnimation_bgAlpha = [CABasicAnimation animation];
    basicAnimation_bgAlpha.delegate = self;
    basicAnimation_bgAlpha.keyPath = @"opacity";
    basicAnimation_bgAlpha.duration = animationTime_bgAlpha;
    basicAnimation_bgAlpha.fromValue = [NSNumber numberWithFloat:0.0f];
    basicAnimation_bgAlpha.toValue = [NSNumber numberWithFloat:1.0f];
    basicAnimation_bgAlpha.removedOnCompletion = NO;
    [_bgView.layer addAnimation:basicAnimation_bgAlpha forKey:kAnimationKey_ShowBgView];
    
    
    switch (_alertViewAnimation) {
            
        case kAlertViewAnimation_VerticalSpring:
        {
            //  出现路径
            [_alertView setCenter:CGPointMake(_bgView.width/2.0, -_alertView.height/2.0)];
            [UIView animateWithDuration:animationTime_keyShow
                                  delay:animationTime_bgAlpha
                 usingSpringWithDamping:0.5
                  initialSpringVelocity:0.7
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [_alertView BearSetCenterToParentViewWithAxis:kAXIS_X_Y];
                             }
                             completion:^(BOOL finished) {
                                 _alertViewAnimationState = kAlertViewAnimationState_Null;
                             }];
        }
            break;
            
        case kAlertViewAnimation_CenterScale:
        {
            //  出现路径
            _alertView.hidden = YES;
            [_alertView BearSetCenterToParentViewWithAxis:kAXIS_X_Y];
            
            CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animation];
            keyFrameAnimation.delegate = self;
            keyFrameAnimation.keyPath = @"transform.scale";
            NSArray *array_my = @[@0.2, @1.1, @0.9, @1.0];
            keyFrameAnimation.values = array_my;
            keyFrameAnimation.duration = animationTime_keyShow;
            keyFrameAnimation.beginTime = CACurrentMediaTime() + animationTime_bgAlpha;
            keyFrameAnimation.removedOnCompletion = NO;
            keyFrameAnimation.fillMode = kCAFillModeForwards;
            [_alertView.layer addAnimation:keyFrameAnimation forKey:kAnimationKey_ShowUDAlertViewScale];
        }
            
        default:
            break;
    }
    
}

/**
 *  AlertView消退动画
 */
- (void)animationClose_udAlertView
{
    if (_alertViewAnimationState == kAlertViewAnimationState_Process) {
        return;
    }
    
    _alertViewAnimationState = kAlertViewAnimationState_Process;
    
    CGFloat animationTime_keyClose = 0.3;
    CGFloat animationTime_bgAlpha = 0.3;
    
    switch (_alertViewAnimation) {
            
        case kAlertViewAnimation_VerticalSpring:
        {
            
        }
            break;
            
        case kAlertViewAnimation_CenterScale:
        {
            
        }
            
        default:
            break;
    }
    
    //  消失路径
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(_bgView.width/2.0, _bgView.height/2.0)];
    [bezierPath addLineToPoint:CGPointMake(_bgView.width/2.0, _bgView.height + _alertView.height)];
    
    CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animation];
    keyFrameAnimation.delegate = self;
    keyFrameAnimation.keyPath = @"position";
    keyFrameAnimation.duration = animationTime_keyClose;
    keyFrameAnimation.path = bezierPath.CGPath;
    keyFrameAnimation.removedOnCompletion = NO;
    keyFrameAnimation.fillMode = kCAFillModeForwards;
    [_alertView.layer addAnimation:keyFrameAnimation forKey:kAnimationKey_CloseUDAlertView];
    
    
    //  背景透明度
    CABasicAnimation *basicAnimation_bgAlpha = [CABasicAnimation animation];
    basicAnimation_bgAlpha.delegate = self;
    basicAnimation_bgAlpha.keyPath = @"opacity";
    basicAnimation_bgAlpha.duration = animationTime_bgAlpha;
    basicAnimation_bgAlpha.fromValue = [NSNumber numberWithFloat:1.0];
    basicAnimation_bgAlpha.toValue = [NSNumber numberWithFloat:0.0];
    basicAnimation_bgAlpha.beginTime = CACurrentMediaTime() + animationTime_keyClose;
    basicAnimation_bgAlpha.removedOnCompletion = NO;
    basicAnimation_bgAlpha.fillMode = kCAFillModeForwards;
    [_bgView.layer addAnimation:basicAnimation_bgAlpha forKey:kAnimationKey_HideBgView];
}


//  Animation Delegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim isEqual:[_alertView.layer animationForKey:kAnimationKey_ShowUDAlertView]]) {
        
        _alertViewAnimationState = kAlertViewAnimationState_Null;
        
        [_alertView BearSetCenterToParentViewWithAxis:kAXIS_X_Y];
        [_alertView.layer removeAnimationForKey:kAnimationKey_ShowUDAlertView];
    }
    
    
    else if ([anim isEqual:[_alertView.layer animationForKey:kAnimationKey_CloseUDAlertView]]){
        
        [_alertView.layer removeAnimationForKey:kAnimationKey_CloseUDAlertView];
        [_alertView removeFromSuperview];
    }
    
    
    else if ([anim isEqual:[_bgView.layer animationForKey:kAnimationKey_ShowBgView]]){
        
        [_bgView.layer removeAnimationForKey:kAnimationKey_ShowBgView];
        
        if (_alertViewAnimation == kAlertViewAnimation_CenterScale) {
            _alertView.hidden = NO;
        }
        
    }
    
    
    else if ([anim isEqual:[_bgView.layer animationForKey:kAnimationKey_HideBgView]]){
        
        _alertViewAnimationState = kAlertViewAnimationState_Null;
        
        [_bgView.layer removeAnimationForKey:kAnimationKey_HideBgView];
        [_bgView removeFromSuperview];
        [self removeFromSuperview];
        
        if (self.animationFinishBlock) {
            self.animationFinishBlock();
        }
        
        if (self.animationClose_FinishBlock) {
            self.animationClose_FinishBlock();
        }
    }
    
    
    else if ([anim isEqual:[_alertView.layer animationForKey:kAnimationKey_ShowUDAlertViewScale]]){
        
        _alertViewAnimationState = kAlertViewAnimationState_Null;
        
        [_alertView.layer removeAnimationForKey:kAnimationKey_ShowUDAlertViewScale];
    }
    
}



@end
