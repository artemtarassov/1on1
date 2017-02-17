//
//  NotificationViewController.m
//  noteContentExt
//
//  Created by Artem Tarassov on 12/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import "MsgModel.h"

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification
{
    NSString * msg=notification.request.content.body;
    
    BOOL hideTag=[msg containsString:@"#hide"];
    if (hideTag) {
        self.label.text=@"......hidden message.....";
    } else {
        self.label.text = msg;
    }
    
    [[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_OPPONENT msg:msg propagate:NO];
    
}

@end
