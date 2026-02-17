#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// UITextSelectionView manuell deklarieren (nicht vollständig im SDK)
@interface UITextSelectionView : UIView
@end

// Einstellungen
static NSMutableDictionary *enabledApps = nil;
static NSString *targetLanguage = @"de";

// Helper für keyWindow
static UIWindow* getKeyWindow() {
    UIWindow *foundWindow = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

// Check ob App aktiviert ist
static BOOL isAppEnabled() {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!enabledApps || enabledApps.count == 0) return YES;
    return [[enabledApps objectForKey:bundleID] boolValue];
}

// Google Translate Helper
@interface TranslateHelper : NSObject
+ (void)translateText:(NSString *)text toLanguage:(NSString *)lang completion:(void(^)(NSString *result, NSError *error))completion;
@end

@implementation TranslateHelper

+ (void)translateText:(NSString *)text toLanguage:(NSString *)lang completion:(void(^)(NSString *result, NSError *error))completion {
    if (!text || text.length == 0) {
        completion(nil, [NSError errorWithDomain:@"TranslateError" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Kein Text"}]);
        return;
    }
    
    NSString *encoded = [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlStr = [NSString stringWithFormat:@"https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=%@&dt=t&q=%@", lang, encoded];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error ?: [NSError errorWithDomain:@"TranslateError" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Netzwerkfehler"}]);
            });
            return;
        }
        
        NSError *jsonError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || ![json isKindOfClass:[NSArray class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, [NSError errorWithDomain:@"TranslateError" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Ungültige Antwort"}]);
            });
            return;
        }
        
        NSArray *result = json;
        if (result.count > 0 && [result[0] isKindOfClass:[NSArray class]]) {
            NSMutableString *translated = [NSMutableString string];
            for (id part in result[0]) {
                if ([part isKindOfClass:[NSArray class]] && [part count] > 0) {
                    [translated appendString:part[0]];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(translated.length > 0 ? translated : text, nil);
            });
        }
    }] resume];
}

@end

// Translate Button Klasse
@interface QTTranslateButton : UIButton
@property (nonatomic, strong) NSString *selectedText;
@end

@implementation QTTranslateButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setTitle:@"🌐 Übersetzen" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor systemBlueColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        self.layer.cornerRadius = 8;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 4;
        [self addTarget:self action:@selector(translateTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)translateTapped {
    if (!self.selectedText || self.selectedText.length == 0) return;
    
    [self setTitle:@"⏳" forState:UIControlStateNormal];
    self.enabled = NO;
    
    NSString *textToTranslate = self.selectedText;
    
    [TranslateHelper translateText:textToTranslate toLanguage:targetLanguage completion:^(NSString *result, NSError *error) {
        self.enabled = YES;
        [self setTitle:@"🌐 Übersetzen" forState:UIControlStateNormal];
        
        if (error) {
            [self showPopup:@"❌ Fehler" message:error.localizedDescription];
        } else {
            [self showPopup:@"✅ Übersetzung" message:result];
        }
    }];
}

- (void)showPopup:(NSString *)title message:(NSString *)message {
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    [[window viewWithTag:88888] removeFromSuperview];
    
    UIView *backdrop = [[UIView alloc] initWithFrame:window.bounds];
    backdrop.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    backdrop.tag = 88888;
    backdrop.alpha = 0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPopup)];
    [backdrop addGestureRecognizer:tap];
    
    UIView *popup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
    popup.center = backdrop.center;
    popup.backgroundColor = [UIColor systemBackgroundColor];
    popup.layer.cornerRadius = 16;
    popup.layer.shadowColor = [UIColor blackColor].CGColor;
    popup.layer.shadowOpacity = 0.3;
    popup.layer.shadowOffset = CGSizeMake(0, 4);
    popup.layer.shadowRadius = 12;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 16, 280, 28)];
    titleLabel.text = title;
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = [UIColor systemBlueColor];
    [popup addSubview:titleLabel];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 320, 0.5)];
    separator.backgroundColor = [UIColor separatorColor];
    [popup addSubview:separator];
    
    UITextView *messageView = [[UITextView alloc] initWithFrame:CGRectMake(16, 58, 288, 118)];
    messageView.text = message;
    messageView.font = [UIFont systemFontOfSize:15];
    messageView.backgroundColor = [UIColor clearColor];
    messageView.editable = NO;
    messageView.scrollEnabled = YES;
    [popup addSubview:messageView];
    
    UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    copyBtn.frame = CGRectMake(16, 190, 134, 36);
    [copyBtn setTitle:@"📋 Kopieren" forState:UIControlStateNormal];
    copyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    copyBtn.backgroundColor = [UIColor systemBlueColor];
    [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    copyBtn.layer.cornerRadius = 10;
    objc_setAssociatedObject(copyBtn, "msgText", message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [copyBtn addTarget:self action:@selector(copyText:) forControlEvents:UIControlEventTouchUpInside];
    [popup addSubview:copyBtn];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(170, 190, 134, 36);
    [closeBtn setTitle:@"Schließen" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    closeBtn.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [closeBtn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn addTarget:self action:@selector(dismissPopup) forControlEvents:UIControlEventTouchUpInside];
    [popup addSubview:closeBtn];
    
    [backdrop addSubview:popup];
    [window addSubview:backdrop];
    
    popup.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        backdrop.alpha = 1;
        popup.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)copyText:(UIButton *)sender {
    NSString *text = objc_getAssociatedObject(sender, "msgText");
    if (text) {
        [UIPasteboard generalPasteboard].string = text;
        [sender setTitle:@"✓ Kopiert!" forState:UIControlStateNormal];
        sender.enabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissPopup];
        });
    }
}

- (void)dismissPopup {
    UIWindow *window = getKeyWindow();
    UIView *backdrop = [window viewWithTag:88888];
    [UIView animateWithDuration:0.25 animations:^{
        backdrop.alpha = 0;
        for (UIView *sub in backdrop.subviews) {
            sub.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }
    } completion:^(BOOL done) {
        [backdrop removeFromSuperview];
    }];
}

@end

// Hook UITextSelectionView
%hook UITextSelectionView

- (void)didMoveToWindow {
    %orig;
    
    if (!isAppEnabled()) return;
    
    UIView *selfView = (UIView *)self;
    [[selfView viewWithTag:77777] removeFromSuperview];
    
    NSString *selectedText = nil;
    UIResponder *responder = selfView.nextResponder;
    
    while (responder) {
        if ([responder conformsToProtocol:@protocol(UITextInput)]) {
            id<UITextInput> textInput = (id<UITextInput>)responder;
            UITextRange *range = [textInput selectedTextRange];
            if (range && ![range isEmpty]) {
                selectedText = [textInput textInRange:range];
            }
            break;
        }
        responder = [responder nextResponder];
    }
    
    if (!selectedText || selectedText.length == 0) return;
    
    QTTranslateButton *button = [[QTTranslateButton alloc] initWithFrame:CGRectMake(0, 0, 130, 32)];
    button.tag = 77777;
    button.selectedText = selectedText;
    
    CGRect bounds = selfView.bounds;
    button.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height + 22);
    
    [selfView addSubview:button];
}

%end

static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.hombergerkurde.quicktranslate.plist"];
    if (prefs) {
        targetLanguage = prefs[@"targetLanguage"] ?: @"de";
        enabledApps = [prefs[@"enabledApplications"] mutableCopy] ?: [NSMutableDictionary dictionary];
    }
}

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.hombergerkurde.quicktranslate/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
