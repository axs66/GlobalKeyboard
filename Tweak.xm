#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "GlobalKeyboardHelper.h"

// 使用更兼容的方式初始化
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        %init;
        
        // 检查是否在 SpringBoard 环境中
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            NSLog(@"✅ GlobalKeyboard 在 SpringBoard 中加载");
            [[GlobalKeyboardManager sharedInstance] initializeGlobalKeyboard];
        } else {
            NSLog(@"🔵 GlobalKeyboard 在应用 %@ 中加载", bundleIdentifier);
        }
    });
}

// 只在 SpringBoard 中 hook motionEnded
%group SpringBoardHook

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[GlobalKeyboardManager sharedInstance] initializeGlobalKeyboard];
    });
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    %orig;
    
    if (motion == UIEventSubtypeMotionShake) {
        [[GlobalKeyboardManager sharedInstance] toggleKeyboard];
    }
}

%end

%end

// 在其他应用中 hook UIApplication
%group AppHook

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

%end

%end

%hook UITextField

- (void)becomeFirstResponder {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

- (void)resignFirstResponder {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

- (void)setText:(NSString *)text {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

%end

%hook UITextView

- (void)becomeFirstResponder {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

- (void)resignFirstResponder {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

- (void)setText:(NSString *)text {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

%end

// 根据运行环境初始化不同的 hook 组
%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardHook);
    } else {
        %init(AppHook);
    }
    
    NSLog(@"✅ GlobalKeyboard插件加载完成 - 环境: %@", bundleIdentifier);
}
