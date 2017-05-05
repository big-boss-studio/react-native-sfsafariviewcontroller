#import "RCTSFSafariViewController.h"

@implementation RCTSFSafariViewController

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.bridge.eventDispatcher sendAppEventWithName:@"SFSafariViewControllerDismissed" body:nil];
}

- (NSString *)valueForKey:(NSString *)key
           fromQueryItems:(NSArray *)queryItems
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
    NSURLQueryItem *queryItem = [[queryItems
                                  filteredArrayUsingPredicate:predicate]
                                 firstObject];
    return queryItem.value;
}

- (void) receiveTestNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    
    if ([[notification name] isEqualToString:@"safariCode"]){
        
        NSArray *queryItems = notification.object;
        
        NSString *code = [self valueForKey:@"code" fromQueryItems:queryItems];
        
        [self.bridge.eventDispatcher sendAppEventWithName:@"SFSafariViewControllerBackSafari" body:code];
        
        NSLog (@"Successfully received the test notification! %@", code);
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

RCT_EXPORT_METHOD(openURL:(NSString *)urlString params:(NSDictionary *)params) {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTestNotification:)
                                                 name:@"safariCode"
                                               object:nil];
    
    
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:safariViewController];
    
    [navigationController setNavigationBarHidden:YES animated:NO];
    safariViewController.delegate = self;
    
    if ([params objectForKey:@"tintColor"]) {
        UIColor *tintColor = [RCTConvert UIColor:params[@"tintColor"]];
        
        if([safariViewController respondsToSelector:@selector(setPreferredControlTintColor:)]) {
            safariViewController.preferredControlTintColor = tintColor;
        } else {
            safariViewController.view.tintColor = tintColor;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [rootViewController presentViewController:navigationController animated:YES completion:^{
            [self.bridge.eventDispatcher sendDeviceEventWithName:@"SFSafariViewControllerDidLoad" body:nil];
        }];
    });
}

RCT_EXPORT_METHOD(close) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [[[UIApplication sharedApplication] delegate] window].rootViewController;
        [rootViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
