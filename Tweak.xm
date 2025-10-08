#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "GlobalKeyboardHelper.h"

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

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    %orig;
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

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

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        %init;
        NSLog(@"✅ GlobalKeyboard插件加载完成");
    });
}
