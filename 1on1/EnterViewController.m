//
//  EnterViewController.m
//  1on1
//
//  Created by Artem Tarassov on 01/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//
#import "EnterViewController.h"
#import <Foundation/Foundation.h>
#import <OneSignal/OneSignal.h>
#include "MsgModel.h"

@interface EnterViewController ()

@end

@implementation EnterViewController

-(void)viewDidUnload
{
    [super viewDidUnload];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setStatusBarBackgroundColor:[UIColor whiteColor]];
    
    self.currentVC=nil;
    self.currentVcName=nil;
    [self addListener];
    [self updateState];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}
-(void)addListener
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAlertPermissions:) name:EVENT_ALERT_PERMISSIONS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPairRequest:) name:EVENT_PAIR_REQUEST object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPairConfirmed:) name:EVENT_PAIR_CONFIRMED object:nil];
     
}

- (void)onPairConfirmed:(NSNotification *)paramNotification
{
    [self updateState];
}

- (void)onPairRequest:(NSNotification *)paramNotification
{
    [self updateState];
}
- (void)onAlertPermissions:(NSNotification *)paramNotification
{
    [self updateState];
}
-(void)updateState
{
    MsgModel *mm=[MsgModel sharedInstance];
    
    NSString * userid2pair=[mm getPairRequestUserID];
    if (userid2pair!=nil) {
        [self promptPairRequest:userid2pair];
        return;
    }
    NSString * pairedConfirmedUserId=[mm getPairConfirmedUserID];//someone confirmed my pair request
    if (pairedConfirmedUserId!=nil) {
        [mm setPairedUserID:pairedConfirmedUserId];
        [mm removePairConfirmed];
        [self showMessages];
        return;
    }
    NSString * pairedUserId=[mm getPairedUserID];
    if (pairedUserId!=nil) {
        [self showMessages];
        return;
    }
    [self showHow2Pair];
}

-(void)showVC:(NSString *)vcName
{
    if ([self.currentVcName isEqualToString:vcName]) {
        return;
    }
    self.currentVcName=vcName;
    if (self.currentVC!=nil) {
        [self.currentVC removeFromParentViewController];
        self.currentVC=nil;
    }
    
    UIViewController *controller = (UIViewController*)[self.storyboard instantiateViewControllerWithIdentifier: vcName];
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    self.currentVC=controller;
}

-(void)showHow2Pair
{
    [self showVC:@"pairViewController"];
}

-(void)showMessages
{
    [self showVC:@"MsgViewController"];
}


- (void)setStatusBarBackgroundColor:(UIColor *)color {
    
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = color;
    }
}

-(void)sendConfirmPair:(NSString *)pairedUserId
{
    MsgModel * mm=[MsgModel sharedInstance];
    NSString * userid=[mm getUserID];
    NSString * msg=[NSString stringWithFormat:@"Pair Confirmed (%@)", userid];
    [OneSignal postNotification:@{@"content_available": @YES,
                                  @"mutable_content":@YES,
                                  @"contents" : @{@"en": msg},
                                  @"include_player_ids": @[pairedUserId]
                                  }
                      onSuccess:^(NSDictionary *result) {
                          NSLog(@"success!");
                          
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self alertMsg:@"you confirmed the pair request" title:@"success"];
                              [self updateState];
                          });
                          

                      } onFailure:^(NSError *error) {
                          NSLog(@"Error - %@", error.localizedDescription);
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self alertMsg:@"failed to confirm the pair request" title:@"error"];
                              [self updateState];
                            });
                          
                      }
     ];
}


-(void)alertMsg:(NSString *)msg title:(NSString * )ttl
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:ttl
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    
    UIAlertAction* declineAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self updateState];
                                                              
                                                              
                                                          }];
    
    [alert addAction:declineAction];
    
    
    [[self topMostController] presentViewController:alert animated:YES completion:nil];
}


-(void)promptPairRequest:(NSString *)userid2pair
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Please Confirm"
                                                                   message:[NSString stringWithFormat:@"Do you want to pair with device code %@",userid2pair]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* acceptAction = [UIAlertAction actionWithTitle:@"ACCEPT" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             MsgModel *mm=[MsgModel sharedInstance];
                                                             [self sendConfirmPair:userid2pair];
                                                             [mm setPairedUserID:userid2pair];
                                                             [mm removePairRequest];
                                                             [self updateState];
                                                         }];
    
    [alert addAction:acceptAction];
    
    UIAlertAction* declineAction = [UIAlertAction actionWithTitle:@"DECLINE" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             MsgModel *mm=[MsgModel sharedInstance];
                                                             [mm removePairRequest];
                                                             [self updateState];
                                                         
                                                         
                                                         }];
    
    [alert addAction:declineAction];
    
    [[self topMostController] presentViewController:alert animated:YES completion:nil];
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}


@end
