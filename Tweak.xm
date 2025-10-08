#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "GlobalKeyboardHelper.h"

// 简单的函数指针替换方式实现 Hook
static void (*original_UIApplication_sendEvent)(id, SEL, UIEvent*);
static void (*original_UITextField_becomeFirstResponder)(id, SEL);
static void (*original_UITextField_resignFirstResponder)(id, SEL);
static void (*original_UITextField_setText)(id, SEL, NSString*);
static void (*original_UITextView_becomeFirstResponder)(id, SEL);
static void (*original_UITextView_resignFirstResponder)(id, SEL);
static void (*original_UITextView_setText)(id, SEL, NSString*);

// Hook UIApplication sendEvent:
static void hooked_UIApplication_sendEvent(id self, SEL _cmd, UIEvent* event) {
    if (original_UIApplication_sendEvent) {
        original_UIApplication_sendEvent(self, _cmd, event);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

// Hook UITextField methods
static void hooked_UITextField_becomeFirstResponder(id self, SEL _cmd) {
    if (original_UITextField_becomeFirstResponder) {
        original_UITextField_becomeFirstResponder(self, _cmd);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

static void hooked_UITextField_resignFirstResponder(id self, SEL _cmd) {
    if (original_UITextField_resignFirstResponder) {
        original_UITextField_resignFirstResponder(self, _cmd);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

static void hooked_UITextField_setText(id self, SEL _cmd, NSString* text) {
    if (original_UITextField_setText) {
        original_UITextField_setText(self, _cmd, text);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

// Hook UITextView methods
static void hooked_UITextView_becomeFirstResponder(id self, SEL _cmd) {
    if (original_UITextView_becomeFirstResponder) {
        original_UITextView_becomeFirstResponder(self, _cmd);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

static void hooked_UITextView_resignFirstResponder(id self, SEL _cmd) {
    if (original_UITextView_resignFirstResponder) {
        original_UITextView_resignFirstResponder(self, _cmd);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

static void hooked_UITextView_setText(id self, SEL _cmd, NSString* text) {
    if (original_UITextView_setText) {
        original_UITextView_setText(self, _cmd, text);
    }
    [[GlobalKeyboardManager sharedInstance] updateButtonStates];
}

// Hook SpringBoard motionEnded for shake gesture
static void (*original_SpringBoard_motionEnded)(id, SEL, UIEventSubtype, UIEvent*);
static void hooked_SpringBoard_motionEnded(id self, SEL _cmd, UIEventSubtype motion, UIEvent* event) {
    if (original_SpringBoard_motionEnded) {
        original_SpringBoard_motionEnded(self, _cmd, motion, event);
    }
    
    if (motion == UIEventSubtypeMotionShake) {
        [[GlobalKeyboardManager sharedInstance] toggleKeyboard];
    }
}

// 设置 Hook
__attribute__((constructor)) static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        // Hook UIApplication
        Class uiApplicationClass = objc_getClass("UIApplication");
        if (uiApplicationClass) {
            Method sendEventMethod = class_getInstanceMethod(uiApplicationClass, @selector(sendEvent:));
            if (sendEventMethod) {
                original_UIApplication_sendEvent = (void (*)(id, SEL, UIEvent*))method_getImplementation(sendEventMethod);
                method_setImplementation(sendEventMethod, (IMP)hooked_UIApplication_sendEvent);
            }
        }
        
        // Hook UITextField
        Class textFieldClass = objc_getClass("UITextField");
        if (textFieldClass) {
            // becomeFirstResponder
            Method becomeFirstResponderMethod = class_getInstanceMethod(textFieldClass, @selector(becomeFirstResponder));
            if (becomeFirstResponderMethod) {
                original_UITextField_becomeFirstResponder = (void (*)(id, SEL))method_getImplementation(becomeFirstResponderMethod);
                method_setImplementation(becomeFirstResponderMethod, (IMP)hooked_UITextField_becomeFirstResponder);
            }
            
            // resignFirstResponder
            Method resignFirstResponderMethod = class_getInstanceMethod(textFieldClass, @selector(resignFirstResponder));
            if (resignFirstResponderMethod) {
                original_UITextField_resignFirstResponder = (void (*)(id, SEL))method_getImplementation(resignFirstResponderMethod);
                method_setImplementation(resignFirstResponderMethod, (IMP)hooked_UITextField_resignFirstResponder);
            }
            
            // setText:
            Method setTextMethod = class_getInstanceMethod(textFieldClass, @selector(setText:));
            if (setTextMethod) {
                original_UITextField_setText = (void (*)(id, SEL, NSString*))method_getImplementation(setTextMethod);
                method_setImplementation(setTextMethod, (IMP)hooked_UITextField_setText);
            }
        }
        
        // Hook UITextView
        Class textViewClass = objc_getClass("UITextView");
        if (textViewClass) {
            // becomeFirstResponder
            Method becomeFirstResponderMethod = class_getInstanceMethod(textViewClass, @selector(becomeFirstResponder));
            if (becomeFirstResponderMethod) {
                original_UITextView_becomeFirstResponder = (void (*)(id, SEL))method_getImplementation(becomeFirstResponderMethod);
                method_setImplementation(becomeFirstResponderMethod, (IMP)hooked_UITextView_becomeFirstResponder);
            }
            
            // resignFirstResponder
            Method resignFirstResponderMethod = class_getInstanceMethod(textViewClass, @selector(resignFirstResponder));
            if (resignFirstResponderMethod) {
                original_UITextView_resignFirstResponder = (void (*)(id, SEL))method_getImplementation(resignFirstResponderMethod);
                method_setImplementation(resignFirstResponderMethod, (IMP)hooked_UITextView_resignFirstResponder);
            }
            
            // setText:
            Method setTextMethod = class_getInstanceMethod(textViewClass, @selector(setText:));
            if (setTextMethod) {
                original_UITextView_setText = (void (*)(id, SEL, NSString*))method_getImplementation(setTextMethod);
                method_setImplementation(setTextMethod, (IMP)hooked_UITextView_setText);
            }
        }
        
        // Hook SpringBoard for shake gesture
        Class springBoardClass = objc_getClass("SpringBoard");
        if (springBoardClass) {
            Method motionEndedMethod = class_getInstanceMethod(springBoardClass, @selector(motionEnded:withEvent:));
            if (motionEndedMethod) {
                original_SpringBoard_motionEnded = (void (*)(id, SEL, UIEventSubtype, UIEvent*))method_getImplementation(motionEndedMethod);
                method_setImplementation(motionEndedMethod, (IMP)hooked_SpringBoard_motionEnded);
            }
        }
        
        // 初始化键盘管理器
        [[GlobalKeyboardManager sharedInstance] initializeGlobalKeyboard];
        
        NSLog(@"✅ GlobalKeyboard插件加载完成");
    });
}
