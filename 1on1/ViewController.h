//
//  ViewController.h
//  1on1
//
//  Created by Artem Tarassov on 30/01/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EasyTableView.h"

@interface ViewController : UIViewController<UITextFieldDelegate,UIWebViewDelegate,EasyTableViewDelegate>
{
    //CGRect _scrollViewStartFrame;

    int _lastMsgIndexAdded;
    
}
@property (retain, nonatomic) EasyTableView *horizontalView;
@property (retain, nonatomic) IBOutlet UIView *hashtagView;
@property (retain, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (retain, nonatomic) IBOutlet UIButton *dateButton;
@property (retain, nonatomic) IBOutlet UIButton *hashtagShowButton;
@property (retain, nonatomic) IBOutlet UIButton *sendNoKeyboardButton;
@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (retain, nonatomic) IBOutlet UITextField *txtInput;
@end

