/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <ABI37_0_0React/ABI37_0_0RCTDevLoadingView.h>

#import <QuartzCore/QuartzCore.h>

#import <ABI37_0_0React/ABI37_0_0RCTBridge.h>
#import <ABI37_0_0React/ABI37_0_0RCTDefines.h>
#import <ABI37_0_0React/ABI37_0_0RCTModalHostViewController.h>
#import <ABI37_0_0React/ABI37_0_0RCTUtils.h>

#if ABI37_0_0RCT_DEV | ABI37_0_0RCT_ENABLE_LOADING_VIEW

static BOOL isEnabled = YES;

@implementation ABI37_0_0RCTDevLoadingView
{
  UIWindow *_window;
  UILabel *_label;
  NSDate *_showDate;
}

@synthesize bridge = _bridge;

ABI37_0_0RCT_EXPORT_MODULE()

+ (void)setEnabled:(BOOL)enabled
{
  isEnabled = enabled;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (void)setBridge:(ABI37_0_0RCTBridge *)bridge
{
  _bridge = bridge;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:ABI37_0_0RCTJavaScriptDidLoadNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(hide)
                                               name:ABI37_0_0RCTJavaScriptDidFailToLoadNotification
                                             object:nil];

  if (bridge.loading) {
    [self showWithURL:bridge.bundleURL];
  }
}

ABI37_0_0RCT_EXPORT_METHOD(showMessage:(NSString *)message color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor)
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_showDate = [NSDate date];
    if (!self->_window && !ABI37_0_0RCTRunningInTestEnvironment()) {
      CGSize screenSize = [UIScreen mainScreen].bounds.size;

      if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        self->_window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, window.safeAreaInsets.top + 30)];
        self->_label = [[UILabel alloc] initWithFrame:CGRectMake(0, window.safeAreaInsets.top, screenSize.width, 30)];
      } else {
        self->_window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, 22)];
        self->_label = [[UILabel alloc] initWithFrame:self->_window.bounds];
      }
      [self->_window addSubview:self->_label];
#if TARGET_OS_TV
      self->_window.windowLevel = UIWindowLevelNormal + 1;
#else
      self->_window.windowLevel = UIWindowLevelStatusBar + 1;
#endif
      // set a root VC so rotation is supported
      self->_window.rootViewController = [UIViewController new];

      self->_label.font = [UIFont monospacedDigitSystemFontOfSize:12.0
                                                           weight:UIFontWeightRegular];
      self->_label.textAlignment = NSTextAlignmentCenter;
    }

    self->_label.text = message;
    self->_label.textColor = color;
    self->_window.backgroundColor = backgroundColor;
    self->_window.hidden = NO;
  });
}

ABI37_0_0RCT_EXPORT_METHOD(hide)
{
  if (!isEnabled) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    const NSTimeInterval MIN_PRESENTED_TIME = 0.6;
    NSTimeInterval presentedTime = [[NSDate date] timeIntervalSinceDate:self->_showDate];
    NSTimeInterval delay = MAX(0, MIN_PRESENTED_TIME - presentedTime);
    CGRect windowFrame = self->_window.frame;
    [UIView animateWithDuration:0.25
                          delay:delay
                        options:0
                     animations:^{
                       self->_window.frame = CGRectOffset(windowFrame, 0, -windowFrame.size.height);
                     } completion:^(__unused BOOL finished) {
                       self->_window.frame = windowFrame;
                       self->_window.hidden = YES;
                       self->_window = nil;
                     }];
  });
}

- (void)showWithURL:(NSURL *)URL
{
  UIColor *color;
  UIColor *backgroundColor;
  NSString *message;
  if (URL.fileURL) {
    // If dev mode is not enabled, we don't want to show this kind of notification
#if !ABI37_0_0RCT_DEV
    return;
#endif
    color = [UIColor whiteColor];
    backgroundColor = [UIColor blackColor];
      message = [NSString stringWithFormat:@"Connect to %@ to develop JavaScript.", ABI37_0_0RCT_PACKAGER_NAME];
  } else {
    color = [UIColor whiteColor];
    backgroundColor = [UIColor colorWithHue:1./3 saturation:1 brightness:.35 alpha:1];
    message = [NSString stringWithFormat:@"Loading from %@:%@...", URL.host, URL.port];
  }

  [self showMessage:message
              color:color
    backgroundColor:backgroundColor];
}

- (void)updateProgress:(ABI37_0_0RCTLoadingProgress *)progress
{
  if (!progress) {
    return;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self->_label.text = [progress description];
  });
}

@end

#else

@implementation ABI37_0_0RCTDevLoadingView

+ (NSString *)moduleName { return nil; }
+ (void)setEnabled:(BOOL)enabled { }
- (void)showMessage:(NSString *)message color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor { }
- (void)showWithURL:(NSURL *)URL { }
- (void)updateProgress:(ABI37_0_0RCTLoadingProgress *)progress { }
- (void)hide { }

@end

#endif
