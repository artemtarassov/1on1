//
//  AppDelegate.m
//  1on1
//
//  Created by Artem Tarassov on 30/01/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import "AppDelegate.h"
#import <OneSignal/OneSignal.h>
#import "MsgModel.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    //let it stay here, otherwise push notification will show an alert window for some reason. (OneSignal bug)
    MsgModel * mm=[MsgModel sharedInstance];
    //
    
    [mm setHasPermissions:[[UIApplication sharedApplication] isRegisteredForRemoteNotifications]];
    
    NSDictionary * settingsDict=@{kOSSettingsKeyInFocusDisplayOption : @(OSNotificationDisplayTypeNone),
                                  kOSSettingsKeyAutoPrompt : @YES};
    
    [OneSignal setLogLevel:ONE_S_LL_NONE visualLevel:ONE_S_LL_NONE];
    [OneSignal IdsAvailable:^(NSString *userId, NSString *pushToken) {
        
         dispatch_async(dispatch_get_main_queue(), ^{
             if(pushToken) {
                 [[MsgModel sharedInstance]setHasPermissions:YES];
             }
             if (userId) {
                 [[MsgModel sharedInstance]setUserID:userId];
             }
         });
    }];
    
    
    [OneSignal initWithLaunchOptions:launchOptions appId:@"19e689fe-b2d2-4e7e-9ad1-a04b9107f99c"
        handleNotificationReceived:^(OSNotification *notification) {
            NSLog(@"OneSignal initWithLaunchOptions handleNotificationReceived");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_OPPONENT msg:notification.payload.body propagate:YES];
            });
            
        }
        handleNotificationAction:nil
        settings:settingsDict
     
     ];
    
 
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[MsgModel sharedInstance]applicationDidBecomeActive];
}



- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
