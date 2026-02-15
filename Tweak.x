#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Einstellungen
static BOOL tweakEnabled = YES;
static NSString *targetLanguage = @"de";

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
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(text, [NSError errorWithDomain:@"TranslateError" code:4 userInfo:@{NSLocalizedDescriptionKey: @"Übersetzung fehlgeschlagen"}]);
            });
        }
    }] resume];
}

@end

// UIMenuController Hook
%hook UIMenuController

- (void)setMenuItems:(NSArray *)items {
    if (!tweakEnabled) {
        %orig;
        return;
    }
    
    NSMutableArray *newItems = items ? [items mutableCopy] : [NSMutableArray array];
    
    BOOL hasTranslate = NO;
    for (UIMenuItem *item in newItems) {
        if ([item.title isEqualToString:@"🌐 Übersetzen"]) {
            hasTranslate = YES;
            break;
        }
    }
    
    if (!hasTranslate) {
        UIMenuItem *translateItem = [[UIMenuItem alloc] initWithTitle:@"🌐 Übersetzen" action:@selector(quickTranslate:)];
        [newItems addObject:translateItem];
    }
    
    %orig(newItems);
}

%end

// UIResponder Hook
%hook UIResponder

%new
- (void)quickTranslate:(id)sender {
    NSString *selectedText = nil;
    
    if ([self conformsToProtocol:@protocol(UITextInput)]) {
        id<UITextInput> textInput = (id<UITextInput>)self;
        UITextRange *range = textInput.selectedTextRange;
        if (range) {
            selectedText = [textInput textInRange:range];
        }
    }
    
    if (!selectedText || selectedText.length == 0) {
        [self showOverlay:@"⚠️ Kein Text markiert" message:@"Bitte markiere zuerst einen Text." isError:YES original:nil];
        return;
    }
    
    [self showLoadingOverlay];
    
    [TranslateHelper translateText:selectedText toLanguage:targetLanguage completion:^(NSString *result, NSError *error) {
        if (error) {
            [self showOverlay:@"❌ Fehler" message:error.localizedDescription isError:YES original:nil];
        } else {
            [self showOverlay:@"✅ Übersetzung" message:result isError:NO original:selectedText];
        }
    }];
}

%new
- (void)showLoadingOverlay {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    [[window viewWithTag:99999] removeFromSuperview];
    
    UIView *backdrop = [[UIView alloc] initWithFrame:window.bounds];
    backdrop.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    backdrop.tag = 99999;
    backdrop.alpha = 0;
    
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 180)];
    overlay.center = backdrop.center;
    overlay.backgroundColor = [UIColor systemBackgroundColor];
    overlay.layer.cornerRadius = 20;
    overlay.layer.shadowColor = [UIColor blackColor].CGColor;
    overlay.layer.shadowOpacity = 0.3;
    overlay.layer.shadowOffset = CGSizeMake(0, 4);
    overlay.layer.shadowRadius = 10;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = CGPointMake(140, 70);
    [spinner startAnimating];
    [overlay addSubview:spinner];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, 240, 50)];
    label.text = @"Übersetze...\n🌐";
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    label.textColor = [UIColor secondaryLabelColor];
    [overlay addSubview:label];
    
    [backdrop addSubview:overlay];
    [window addSubview:backdrop];
    
    [UIView animateWithDuration:0.3 animations:^{
        backdrop.alpha = 1;
    }];
}

%new
- (void)showOverlay:(NSString *)title message:(NSString *)message isError:(BOOL)isError original:(NSString *)original {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    [[window viewWithTag:99999] removeFromSuperview];
    
    UIView *backdrop = [[UIView alloc] initWithFrame:window.bounds];
    backdrop.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    backdrop.tag = 99999;
    backdrop.alpha = 0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
    [backdrop addGestureRecognizer:tap];
    
    CGFloat height = isError ? 200 : 380;
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, height)];
    overlay.center = backdrop.center;
    overlay.backgroundColor = [UIColor systemBackgroundColor];
    overlay.layer.cornerRadius = 20;
    overlay.layer.shadowColor = [UIColor blackColor].CGColor;
    overlay.layer.shadowOpacity = 0.3;
    overlay.layer.shadowOffset = CGSizeMake(0, 4);
    overlay.layer.shadowRadius = 10;
    
    CGFloat y = 20;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 300, 30)];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    titleLabel.textColor = isError ? [UIColor systemRedColor] : [UIColor systemBlueColor];
    [overlay addSubview:titleLabel];
    y += 40;
    
    if (!isError && original) {
        UILabel *origLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 300, 20)];
        origLabel.text = @"Original:";
        origLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        origLabel.textColor = [UIColor secondaryLabelColor];
        [overlay addSubview:origLabel];
        y += 25;
        
        UITextView *origText = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 300, 60)];
        origText.text = original;
        origText.font = [UIFont systemFontOfSize:15];
        origText.backgroundColor = [UIColor secondarySystemBackgroundColor];
        origText.layer.cornerRadius = 10;
        origText.editable = NO;
        origText.scrollEnabled = YES;
        origText.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
        [overlay addSubview:origText];
        y += 70;
        
        UILabel *arrow = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 340, 20)];
        arrow.text = @"↓";
        arrow.textAlignment = NSTextAlignmentCenter;
        arrow.font = [UIFont systemFontOfSize:20];
        arrow.textColor = [UIColor systemBlueColor];
        [overlay addSubview:arrow];
        y += 25;
        
        UILabel *transLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 300, 20)];
        transLabel.text = @"Übersetzt:";
        transLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        transLabel.textColor = [UIColor secondaryLabelColor];
        [overlay addSubview:transLabel];
        y += 25;
    }
    
    UITextView *messageText = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 300, 80)];
    messageText.text = message;
    messageText.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    messageText.backgroundColor = isError ? [[UIColor systemRedColor] colorWithAlphaComponent:0.1] : [[UIColor systemGreenColor] colorWithAlphaComponent:0.1];
    messageText.layer.cornerRadius = 10;
    messageText.layer.borderWidth = 2;
    messageText.layer.borderColor = isError ? [UIColor systemRedColor].CGColor : [UIColor systemGreenColor].CGColor;
    messageText.editable = NO;
    messageText.scrollEnabled = YES;
    messageText.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    [overlay addSubview:messageText];
    y += 90;
    
    if (!isError) {
        objc_setAssociatedObject(backdrop, "translatedText", message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        copyBtn.frame = CGRectMake(20, y, 145, 44);
        [copyBtn setTitle:@"📋 Kopieren" forState:UIControlStateNormal];
        copyBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        copyBtn.backgroundColor = [UIColor systemBlueColor];
        [copyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        copyBtn.layer.cornerRadius = 12;
        [copyBtn addTarget:self action:@selector(copyText:) forControlEvents:UIControlEventTouchUpInside];
        [overlay addSubview:copyBtn];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(175, y, 145, 44);
        [closeBtn setTitle:@"Schließen" forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        closeBtn.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [closeBtn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        closeBtn.layer.cornerRadius = 12;
        [closeBtn addTarget:self action:@selector(dismissOverlay:) forControlEvents:UIControlEventTouchUpInside];
        [overlay addSubview:closeBtn];
    } else {
        UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        okBtn.frame = CGRectMake(70, y, 200, 44);
        [okBtn setTitle:@"OK" forState:UIControlStateNormal];
        okBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        okBtn.backgroundColor = [UIColor systemRedColor];
        [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        okBtn.layer.cornerRadius = 12;
        [okBtn addTarget:self action:@selector(dismissOverlay:) forControlEvents:UIControlEventTouchUpInside];
        [overlay addSubview:okBtn];
    }
    
    [backdrop addSubview:overlay];
    [window addSubview:backdrop];
    
    overlay.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        backdrop.alpha = 1;
        overlay.transform = CGAffineTransformIdentity;
    } completion:nil];
}

%new
- (void)copyText:(UIButton *)sender {
    UIView *backdrop = [[UIApplication sharedApplication].keyWindow viewWithTag:99999];
    NSString *text = objc_getAssociatedObject(backdrop, "translatedText");
    
    if (text) {
        UIPasteboard.generalPasteboard.string = text;
        [sender setTitle:@"✓ Kopiert!" forState:UIControlStateNormal];
        sender.enabled = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissOverlay:nil];
        });
    }
}

%new
- (void)dismissOverlay:(id)sender {
    UIView *backdrop = [[UIApplication sharedApplication].keyWindow viewWithTag:99999];
    [UIView animateWithDuration:0.3 animations:^{
        backdrop.alpha = 0;
        for (UIView *subview in backdrop.subviews) {
            subview.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }
    } completion:^(BOOL finished) {
        [backdrop removeFromSuperview];
    }];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (!tweakEnabled) {
        return %orig;
    }
    
    if (action == @selector(quickTranslate:)) {
        if ([self conformsToProtocol:@protocol(UITextInput)]) {
            id<UITextInput> textInput = (id<UITextInput>)self;
            UITextRange *range = textInput.selectedTextRange;
            return range && ![range isEmpty];
        }
        return NO;
    }
    
    return %orig;
}

%end

// Preferences laden
static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.hombergerkurde.quicktranslate.plist"];
    if (prefs) {
        tweakEnabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
        targetLanguage = [prefs objectForKey:@"targetLanguage"] ?: @"de";
    }
}

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.hombergerkurde.quicktranslate/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
