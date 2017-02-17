//
//  PairViewController.m
//  1on1
//
//  Created by Artem Tarassov on 02/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//
#import "PairViewController.h"
#import <Foundation/Foundation.h>
#import <OneSignal/OneSignal.h>
#import "MsgModel.h"

static int _tagMyUserTxtField=55;

@interface PairViewController ()

@end

@implementation PairViewController


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveUserUpdateNotification:)
                                                 name:EVENT_UPDATE_USERID
                                               object:nil];
    
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scrollViewStartFrame=self.view.frame;
    
    
    NSString * userID=[[MsgModel sharedInstance]getUserID];
    UITextView * myuser=[self.view viewWithTag:_tagMyUserTxtField];
    myuser.layer.borderWidth = 2.0f;
    
    if (userID==nil || [userID length]==0) {
        [myuser setText:@".... loading code ...."];
        //myuser.layer.borderColor = [[UIColor redColor] CGColor];
        [self performSelector:@selector(delayedCall) withObject:nil afterDelay:5.0 ];
        
    }else {
        [myuser setText:userID];
        //myuser.layer.borderColor = [[UIColor grayColor] CGColor];
    }
    
    self.txtViewInput.delegate=self;
    
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.txtViewInput resignFirstResponder];
    return YES;
}


- (void)handleKeyboardWillShow:(NSNotification *)paramNotification

{
    NSDictionary* info = [paramNotification userInfo];

    // size of the keyb that is about to appear
    CGSize kbSizeNew = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //make adjustments to constraints here...
    
    CGRect frame=self.scrollView.frame;
    //frame.size.height-=kbSizeNew.height;
    frame.size.height=self.view.frame.size.height-kbSizeNew.height;
    [self.scrollView setFrame:frame];
    
    //and here where's magick happen!
    
    [self.view layoutIfNeeded];
}

- (void)handleKeyboardWillHide:(NSNotification *)paramNotification
{
    NSDictionary* info = [paramNotification userInfo];
    CGSize kbSizeNew = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    CGRect frame=self.view.frame;
    frame.size.height=self.view.frame.size.height;
    [self.scrollView setFrame:frame];
    
    //and here where's magick happen!
    
    [self.view layoutIfNeeded];
    
}

- (IBAction)onButtonShowInput:(UIButton *)sender
{
    [self.txtViewInput resignFirstResponder];
    [self.txtViewInput setHidden:!self.txtViewInput.hidden];
    [self.sendPairButton setHidden:!self.sendPairButton.hidden];
    
    [self.view layoutIfNeeded];
    
    if (self.scrollView.contentSize.height>self.scrollView.bounds.size.height) {
        
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
        [self.scrollView setContentOffset:bottomOffset animated:YES];
    }
}

-(void)delayedCall
{
    NSString * userID=[[MsgModel sharedInstance]getUserID];
    if (userID==nil || [userID length]==0) {
        UITextView * myuser=[self.view viewWithTag:_tagMyUserTxtField];
        [myuser setText:@"cant get code because there is no internet connection"];
    }
}

- (void)receiveUserUpdateNotification:(NSNotification *) notification
{
    NSString * userID=[[MsgModel sharedInstance]getUserID];
    UITextView * lab=[self.view viewWithTag:_tagMyUserTxtField];
    [lab setText:userID];
    lab.layer.borderColor = [[UIColor grayColor] CGColor];
    NSLog(@"PairViewController receiveUserUpdateNotification userID = %@",userID);
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"PairViewController viewWillDisappear");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [super viewWillDisappear:animated];
}

-(BOOL)checkStates
{
    NSString * userID=[[MsgModel sharedInstance]getUserID];
    if (userID==nil || [userID length]==0) {
        [self alertMsg:@"no internet connection" title:@"error"];
        return NO;
    }
    
    /*
    if (![[MsgModel sharedInstance]getHasPermissions]) {
         NSLog(@"alertMsg checkStates");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"cant proceed"
                                                                       message:@"you need to enable push notifications in order to continue"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        
        
        
        UIAlertAction* declineAction = [UIAlertAction actionWithTitle:@"close" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  //
                                                                  
                                                              }];
        
        
        
        UIAlertAction* proceedAction = [UIAlertAction actionWithTitle:@"enable" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  //
                                                                  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                              }];
        
        [alert addAction:proceedAction];
        [alert addAction:declineAction];
        
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }*/
    return YES;
}

- (IBAction)onCopyToPasteboard:(UIButton *)sender
{
    if (![self checkStates]) {
        return;
    }
    UITextView * myuser=[self.view viewWithTag:_tagMyUserTxtField];
    [[UIPasteboard generalPasteboard]setString:myuser.text];
    
}
- (IBAction)onSendCodeViaEmail:(UIButton *)sender
{
    //
    if (![self checkStates]) {
        return;
    }
    
    UITextView * myuser=[self.view viewWithTag:_tagMyUserTxtField];
    NSString * URLEMail=[NSString stringWithFormat:@"mailto:?subject=1on1 code&body=%@",myuser.text];
    NSString *url = [URLEMail stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
    

}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

- (IBAction)onButtonPressed:(UIButton *)sender
{
    [self.txtViewInput resignFirstResponder];
    if (![self checkStates]) {
        return;
    }
    UITextField * txtOther=self.txtViewInput;
    
    NSString * userid2pair= [txtOther.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
    if ([userid2pair length]<10) {
        [self alertMsg:@"you entered no or an invalid code" title:@"error"];
        return;
    }
    
    NSString * myuser=[[MsgModel sharedInstance]getUserID];
    
    if ([myuser isEqualToString:userid2pair] && ![[MsgModel sharedInstance]getHasPermissions]) {
        //for apple to test
        NSString * fakeMsg=[NSString stringWithFormat:@"Pair Confirmed (%@)",userid2pair];
        [[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_OPPONENT msg:fakeMsg propagate:YES];
        return;
    }
    
    
    NSString * msg=[NSString stringWithFormat:@"Pair Request (%@)",myuser];
    [OneSignal postNotification:@{@"content_available": @YES,
                                  @"mutable_content":@YES,
                                  @"contents" : @{@"en": msg},
                                  @"include_player_ids": @[userid2pair]
                                  }
                      onSuccess:^(NSDictionary *result) {
                          NSLog(@"success!");
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self alertMsg:@"pair request send. please wait for confirmation." title:@"success"];
                          });
                      } onFailure:^(NSError *error) {
                          NSLog(@"Error - %@", error.localizedDescription);
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self alertMsg:@"pair request could not be sent. maybe the given code is wrong" title:@"error"];
                          });
                      }
     ];
}

-(void)alertMsg:(NSString *)msg title:(NSString * )ttl
{
    NSLog(@"alertMsg");
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:ttl
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    
    UIAlertAction* declineAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              //
                                                              
                                                          }];
    
    [alert addAction:declineAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
