#import <Foundation/Foundation.h>

@interface NCNotificationContent : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *message;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, copy, readonly) NSString *sectionIdentifier;
@property (nonatomic, strong, readonly) NCNotificationContent *content;
@end

static NSString * const kServerEndpoint = @"https://hieu-live.duckdns.org/bank-notify";
static NSString * const kSecretKey = @"tweak_bank_secret_2026";
static NSString * const kTargetBundleID = @"com.mbmobile";

static void sendNotificationToServer(NSString *title, NSString *message) {
    if (!message || message.length == 0) return;

    // Chạy ngầm 100% trên luồng background (Zero lag SpringBoard 120Hz)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            // Chỉ bắt các thông báo có dấu hiệu tiền vào (+)
            if (![message containsString:@"+"] && ![message containsString:@"GD: +"]) {
                return;
            }

            NSDictionary *payload = @{
                @"bank": @"MB",
                @"bundle_id": kTargetBundleID,
                @"title": title ?: @"MBBank",
                @"content": message,
                @"timestamp": @((long)[[NSDate date] timeIntervalSince1970])
            };

            NSError *err = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&err];
            if (!jsonData || err) return;

            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kServerEndpoint]];
            [req setHTTPMethod:@"POST"];
            [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [req setValue:kSecretKey forHTTPHeaderField:@"X-Secret-Key"];
            [req setHTTPBody:jsonData];
            [req setTimeoutInterval:10.0];

            NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
            [[session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *res, NSError *error) {
                // Hoàn tất âm thầm
            }] resume];
        }
    });
}

%hook NCNotificationDispatcher
- (void)postNotificationWithRequest:(NCNotificationRequest *)request {
    %orig;
    if (!request) return;

    // Lọc duy nhất app MB Bank trên iOS 16
    NSString *sectionID = [request sectionIdentifier];
    if ([sectionID isEqualToString:kTargetBundleID]) {
        NCNotificationContent *content = [request content];
        NSString *title = [content title];
        NSString *message = [content message];
        sendNotificationToServer(title, message);
    }
}
%end
