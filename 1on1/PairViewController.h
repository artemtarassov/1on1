//
//  PairViewController.h
//  1on1
//
//  Created by Artem Tarassov on 02/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PairViewController : UIViewController<UITextFieldDelegate>
{
    CGRect _scrollViewStartFrame;
}
@property (retain, nonatomic) IBOutlet UIButton * showInputButton;
@property (retain, nonatomic) IBOutlet UIButton * sendPairButton;
@property (retain, nonatomic) IBOutlet UITextField * txtViewInput;
@property (retain, nonatomic) IBOutlet UIScrollView * scrollView;
@end

