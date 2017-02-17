//
//  NotificationService.m
//  noteServiceExt
//
//  Created by Artem Tarassov on 12/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import "NotificationService.h"
#import "MsgModel.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
    NSString * msg=self.bestAttemptContent.body;
    
    self.bestAttemptContent.badge=[NSNumber numberWithInt:1];
    
    BOOL hideTag=[msg containsString:@"#hide"];
    if (hideTag) {
        self.bestAttemptContent.body=@".......hidden message......";
    } else {
        self.bestAttemptContent.body = msg;
    }
    
    [[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_OPPONENT msg:msg propagate:NO];
    self.contentHandler(self.bestAttemptContent);
    
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}

@end
