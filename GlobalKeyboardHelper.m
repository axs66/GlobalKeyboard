#import "GlobalKeyboardHelper.h"
#import <objc/runtime.h>

@implementation GKButtonInfo

- (instancetype)initWithType:(GKButtonType)type title:(NSString *)title iconName:(NSString *)iconName {
    if (self = [super init]) {
        _type = type;
        _title = [title copy];
        _iconName = [iconName copy];
        _enabled = YES;
    }
    return self;
}

@end

@interface GlobalKeyboardManager ()
@property (nonatomic, strong) UIWindow *keyboardWindow;
@property (nonatomic, strong) UIView *keyboardView;
@property (nonatomic, strong) UIStackView *buttonStack;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, strong) NSArray *buttonInfos;
@end

@implementation GlobalKeyboardManager

+ (instancetype)sharedInstance {
    static GlobalKeyboardManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GlobalKeyboardManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _isVisible = NO;
        _buttonInfos = @[
            [[GKButtonInfo alloc] initWithType:GKButtonTypeSelectAll title:@"全选" iconName:@"doc.on.doc"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeCut title:@"剪切" iconName:@"scissors"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeCopy title:@"复制" iconName:@"doc.on.clipboard"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypePaste title:@"粘贴" iconName:@"doc.on.clipboard.fill"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeUndo title:@"撤销" iconName:@"arrow.uturn.backward"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeRedo title:@"重做" iconName:@"arrow.uturn.forward"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeDelete title:@"删除" iconName:@"delete.left"],
            [[GKButtonInfo alloc] initWithType:GKButtonTypeClose title:@"关闭" iconName:@"xmark.circle"]
        ];
    }
    return self;
}

- (void)initializeGlobalKeyboard {
    [self setupKeyboardWindow];
    NSLog(@"✅ GlobalKeyboard初始化完成");
}

- (void)setupKeyboardWindow {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat keyboardHeight = 70.0f;
    CGRect keyboardFrame = CGRectMake(screenBounds.size.width/2 - 200, 
                                     screenBounds.size.height - 150, 
                                     400, keyboardHeight);
    
    self.keyboardWindow = [[UIWindow alloc] initWithFrame:keyboardFrame];
    self.keyboardWindow.windowLevel = UIWindowLevelStatusBar + 1000;
    self.keyboardWindow.backgroundColor = [UIColor clearColor];
    self.keyboardWindow.hidden = YES;
    self.keyboardWindow.userInteractionEnabled = YES;
    self.keyboardWindow.layer.cornerRadius = 15.0f;
    self.keyboardWindow.clipsToBounds = YES;
    
    self.keyboardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, keyboardHeight)];
    self.keyboardView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    self.keyboardView.layer.cornerRadius = 15.0f;
    self.keyboardView.clipsToBounds = YES;
    
    // 毛玻璃效果
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.keyboardView.bounds;
    [self.keyboardView addSubview:blurView];
    
    // 按钮堆栈
    self.buttonStack = [[UIStackView alloc] initWithFrame:CGRectMake(10, 10, 380, 50)];
    self.buttonStack.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStack.distribution = UIStackViewDistributionFillEqually;
    self.buttonStack.spacing = 6.0f;
    self.buttonStack.alignment = UIStackViewAlignmentCenter;
    
    [self.keyboardView addSubview:self.buttonStack];
    [self.keyboardWindow addSubview:self.keyboardView];
    
    [self createButtons];
    [self setupGestures];
}

- (void)createButtons {
    for (GKButtonInfo *buttonInfo in self.buttonInfos) {
        UIButton *button = [self createButtonWithInfo:buttonInfo];
        [self.buttonStack addArrangedSubview:button];
    }
}

- (UIButton *)createButtonWithInfo:(GKButtonInfo *)buttonInfo {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [button setImage:[UIImage systemImageNamed:buttonInfo.iconName] forState:UIControlStateNormal];
    [button setTitle:buttonInfo.title forState:UIControlStateNormal];
    [button setTintColor:[UIColor whiteColor]];
    button.titleLabel.font = [UIFont systemFontOfSize:9];
    
    // 垂直排列
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 12, 0);
    button.titleEdgeInsets = UIEdgeInsetsMake(25, -25, 0, 0);
    
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    button.layer.cornerRadius = 8.0f;
    button.clipsToBounds = YES;
    
    objc_setAssociatedObject(button, "buttonInfo", buttonInfo, OBJC_ASSOCIATION_RETAIN);
    [button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:40],
        [button.heightAnchor constraintEqualToConstant:40]
    ]];
    
    return button;
}

- (void)setupGestures {
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] 
                                         initWithTarget:self 
                                         action:@selector(handlePanGesture:)];
    [self.keyboardView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
                                        initWithTarget:self 
                                        action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.keyboardView addGestureRecognizer:tapGesture];
}

- (void)handleButtonTap:(UIButton *)sender {
    GKButtonInfo *buttonInfo = objc_getAssociatedObject(sender, "buttonInfo");
    if (!buttonInfo || !buttonInfo.enabled) return;
    
    [self performActionForButtonType:buttonInfo.type];
}

- (void)performActionForButtonType:(GKButtonType)type {
    UIResponder *firstResponder = [self findFirstResponder];
    if (!firstResponder) return;
    
    switch (type) {
        case GKButtonTypeSelectAll:
            if ([firstResponder respondsToSelector:@selector(selectAll:)]) {
                [firstResponder performSelector:@selector(selectAll:) withObject:nil];
            }
            break;
        case GKButtonTypeCut:
            if ([firstResponder respondsToSelector:@selector(cut:)]) {
                [firstResponder performSelector:@selector(cut:) withObject:nil];
            }
            break;
        case GKButtonTypeCopy:
            if ([firstResponder respondsToSelector:@selector(copy:)]) {
                [firstResponder performSelector:@selector(copy:) withObject:nil];
            }
            break;
        case GKButtonTypePaste:
            if ([firstResponder respondsToSelector:@selector(paste:)]) {
                [firstResponder performSelector:@selector(paste:) withObject:nil];
            }
            break;
        case GKButtonTypeUndo:
            // 使用更安全的方式执行撤销
            [self performUndoAction];
            break;
        case GKButtonTypeRedo:
            // 使用更安全的方式执行重做
            [self performRedoAction];
            break;
        case GKButtonTypeDelete:
            // 模拟删除键
            [self simulateDeleteKey];
            break;
        case GKButtonTypeClose:
            [self hideKeyboard];
            break;
    }
}

- (void)performUndoAction {
    UIResponder *firstResponder = [self findFirstResponder];
    if (!firstResponder) return;
    
    // 尝试多种方式执行撤销
    if ([firstResponder respondsToSelector:@selector(undoManager)]) {
        NSUndoManager *undoManager = [firstResponder valueForKey:@"undoManager"];
        if (undoManager && [undoManager canUndo]) {
            [undoManager undo];
        }
    } else if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        if ([textField.undoManager canUndo]) {
            [textField.undoManager undo];
        }
    } else if ([firstResponder isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)firstResponder;
        if ([textView.undoManager canUndo]) {
            [textView.undoManager undo];
        }
    }
}

- (void)performRedoAction {
    UIResponder *firstResponder = [self findFirstResponder];
    if (!firstResponder) return;
    
    // 尝试多种方式执行重做
    if ([firstResponder respondsToSelector:@selector(undoManager)]) {
        NSUndoManager *undoManager = [firstResponder valueForKey:@"undoManager"];
        if (undoManager && [undoManager canRedo]) {
            [undoManager redo];
        }
    } else if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        if ([textField.undoManager canRedo]) {
            [textField.undoManager redo];
        }
    } else if ([firstResponder isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)firstResponder;
        if ([textView.undoManager canRedo]) {
            [textView.undoManager redo];
        }
    }
}

- (void)simulateDeleteKey {
    UIResponder *firstResponder = [self findFirstResponder];
    if (!firstResponder) return;
    
    if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        if (textField.text.length > 0) {
            NSRange selectedRange = [self getSelectedRange:textField];
            if (selectedRange.length > 0) {
                // 删除选中文本
                textField.text = [textField.text stringByReplacingCharactersInRange:selectedRange withString:@""];
            } else if (selectedRange.location > 0) {
                // 删除前一个字符
                NSRange deleteRange = NSMakeRange(selectedRange.location - 1, 1);
                textField.text = [textField.text stringByReplacingCharactersInRange:deleteRange withString:@""];
                [self setSelectedRange:NSMakeRange(deleteRange.location, 0) forTextField:textField];
            }
        }
    } else if ([firstResponder isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)firstResponder;
        if (textView.text.length > 0) {
            NSRange selectedRange = textView.selectedRange;
            if (selectedRange.length > 0) {
                // 删除选中文本
                textView.text = [textView.text stringByReplacingCharactersInRange:selectedRange withString:@""];
                textView.selectedRange = NSMakeRange(selectedRange.location, 0);
            } else if (selectedRange.location > 0) {
                // 删除前一个字符
                NSRange deleteRange = NSMakeRange(selectedRange.location - 1, 1);
                textView.text = [textView.text stringByReplacingCharactersInRange:deleteRange withString:@""];
                textView.selectedRange = NSMakeRange(deleteRange.location, 0);
            }
        }
    }
}

- (NSRange)getSelectedRange:(UITextField *)textField {
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextPosition *start = textField.selectedTextRange.start;
    UITextPosition *end = textField.selectedTextRange.end;
    
    NSInteger location = [textField offsetFromPosition:beginning toPosition:start];
    NSInteger length = [textField offsetFromPosition:start toPosition:end];
    
    return NSMakeRange(location, length);
}

- (void)setSelectedRange:(NSRange)range forTextField:(UITextField *)textField {
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextPosition *start = [textField positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [textField positionFromPosition:start offset:range.length];
    UITextRange *textRange = [textField textRangeFromPosition:start toPosition:end];
    textField.selectedTextRange = textRange;
}

- (UIResponder *)findFirstResponder {
    // 使用兼容的方式获取key window
    UIWindow *keyWindow = [self getKeyWindow];
    return [self findFirstResponderInView:keyWindow];
}

- (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;
    
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
        
        // 如果没有找到key window，使用第一个窗口
        if (!keyWindow) {
            for (UIScene *scene in connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    keyWindow = windowScene.windows.firstObject;
                    break;
                }
            }
        }
    } else {
        // 对于 iOS 12 及以下版本
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [UIApplication sharedApplication].keyWindow;
        #pragma clang diagnostic pop
    }
    
    // 最后尝试使用windows数组
    if (!keyWindow) {
        NSArray<UIWindow *> *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow) {
            keyWindow = windows.firstObject;
        }
    }
    
    return keyWindow;
}

- (UIResponder *)findFirstResponderInView:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    }
    
    for (UIView *subview in view.subviews) {
        UIResponder *firstResponder = [self findFirstResponderInView:subview];
        if (firstResponder) {
            return firstResponder;
        }
    }
    
    return nil;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    static CGPoint originalCenter;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        originalCenter = self.keyboardView.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self.keyboardWindow];
        self.keyboardView.center = CGPointMake(originalCenter.x + translation.x, 
                                             originalCenter.y + translation.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // 边界检查
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGRect keyboardFrame = self.keyboardWindow.frame;
        
        CGFloat minX = 0;
        CGFloat maxX = screenBounds.size.width - keyboardFrame.size.width;
        CGFloat minY = 100; // 距离顶部最小距离
        CGFloat maxY = screenBounds.size.height - 100; // 距离底部最小距离
        
        CGRect newFrame = keyboardFrame;
        newFrame.origin.x = MAX(minX, MIN(newFrame.origin.x, maxX));
        newFrame.origin.y = MAX(minY, MIN(newFrame.origin.y, maxY));
        
        [UIView animateWithDuration:0.3 animations:^{
            self.keyboardWindow.frame = newFrame;
        }];
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        [self hideKeyboard];
    }
}

#pragma mark - Public Methods

- (void)showKeyboard {
    if (_isVisible) return;
    
    self.keyboardWindow.hidden = NO;
    _isVisible = YES;
    
    self.keyboardView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.3 
                          delay:0 
         usingSpringWithDamping:0.7 
          initialSpringVelocity:0.5 
                        options:UIViewAnimationOptionCurveEaseOut 
                     animations:^{
        self.keyboardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hideKeyboard {
    if (!_isVisible) return;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.keyboardView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.keyboardView.alpha = 0;
    } completion:^(BOOL finished) {
        self.keyboardWindow.hidden = YES;
        self.keyboardView.transform = CGAffineTransformIdentity;
        self.keyboardView.alpha = 1;
        self->_isVisible = NO;
    }];
}

- (void)toggleKeyboard {
    if (_isVisible) {
        [self hideKeyboard];
    } else {
        [self showKeyboard];
    }
}

- (BOOL)isKeyboardVisible {
    return _isVisible;
}

- (void)updateButtonStates {
    UIResponder *firstResponder = [self findFirstResponder];
    BOOL hasText = NO;
    BOOL canPaste = [[UIPasteboard generalPasteboard] string].length > 0;
    
    if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        hasText = textField.text.length > 0;
    } else if ([firstResponder isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)firstResponder;
        hasText = textView.text.length > 0;
    }
    
    // 检查撤销/重做状态
    BOOL canUndo = NO;
    BOOL canRedo = NO;
    
    if ([firstResponder respondsToSelector:@selector(undoManager)]) {
        NSUndoManager *undoManager = [firstResponder valueForKey:@"undoManager"];
        canUndo = undoManager.canUndo;
        canRedo = undoManager.canRedo;
    } else if ([firstResponder isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)firstResponder;
        canUndo = textField.undoManager.canUndo;
        canRedo = textField.undoManager.canRedo;
    } else if ([firstResponder isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)firstResponder;
        canUndo = textView.undoManager.canUndo;
        canRedo = textView.undoManager.canRedo;
    }
    
    for (UIView *view in self.buttonStack.arrangedSubviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;
            GKButtonInfo *buttonInfo = objc_getAssociatedObject(button, "buttonInfo");
            
            if (buttonInfo) {
                BOOL shouldEnable = YES;
                
                switch (buttonInfo.type) {
                    case GKButtonTypeSelectAll:
                    case GKButtonTypeCut:
                    case GKButtonTypeCopy:
                    case GKButtonTypeDelete:
                        shouldEnable = hasText;
                        break;
                    case GKButtonTypePaste:
                        shouldEnable = canPaste;
                        break;
                    case GKButtonTypeUndo:
                        shouldEnable = canUndo;
                        break;
                    case GKButtonTypeRedo:
                        shouldEnable = canRedo;
                        break;
                    case GKButtonTypeClose:
                        shouldEnable = YES;
                        break;
                    default:
                        shouldEnable = YES;
                        break;
                }
                
                button.enabled = shouldEnable;
                button.alpha = shouldEnable ? 1.0 : 0.3;
                buttonInfo.enabled = shouldEnable;
            }
        }
    }
}

@end
