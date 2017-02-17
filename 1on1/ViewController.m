//
//  ViewController.m
//  1on1
//
//  Created by Artem Tarassov on 30/01/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//

#import "ViewController.h"
#import <OneSignal/OneSignal.h>
#import "MsgModel.h"
#import "EasyTableViewController.h"
#import "1on1-Bridging-Header.h"
#import <AudioToolbox/AudioToolbox.h>

#define HORIZONTAL_TABLEVIEW_HEIGHT	50
#define VERTICAL_TABLEVIEW_WIDTH	120
#define CELL_BACKGROUND_COLOR		[UIColor clearColor]

#define BORDER_VIEW_TAG				10

#ifdef SHOW_MULTIPLE_SECTIONS
#define NUM_OF_CELLS			10
#define NUM_OF_SECTIONS			2
#else
#define NUM_OF_CELLS			9
#endif


@interface ViewController ()
@end


@implementation ViewController {
    NSIndexPath *_selectedVerticalIndexPath;
    NSIndexPath *_selectedHorizontalIndexPath;
}

-(void)alertPermissions
{
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"notice"
     message:@"please enable push notifications so you can also receive messages when 1on1 is not running"
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

}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (!self.hashtagView.hidden) {
        [self triggerHashtags];
    }
}

-(float)getHeightInConstraint:(UIView *)myView
{
    NSLayoutConstraint *heightConstraint=nil;
    for (NSLayoutConstraint *constraint in myView.constraints) {
        if (constraint.firstAttribute == NSLayoutAttributeHeight) {
            heightConstraint = constraint;
            break;
        }
    }
    if (heightConstraint==nil) {
        return 0;
    }
    return heightConstraint.constant;
}

-(void)triggerHashtags
{

    if (self.horizontalView==nil) {
        CGSize hvSize;
        hvSize.width=self.hashtagView.frame.size.width;
        hvSize.height=[self getHeightInConstraint:self.hashtagView];
        
        CGRect frameRect;
        frameRect.origin=CGPointMake(0, -hvSize.height);
        frameRect.size=hvSize;
        
        EasyTableView *view	= [[EasyTableView alloc] initWithFrame:frameRect ofWidth:VERTICAL_TABLEVIEW_WIDTH];
        self.horizontalView = view;
        
        self.horizontalView.delegate					= self;
        self.horizontalView.tableView.backgroundColor	= [UIColor clearColor];
        self.horizontalView.tableView.allowsSelection	= YES;
        self.horizontalView.tableView.separatorColor	= [UIColor darkGrayColor];
        self.horizontalView.autoresizingMask			= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
    
    if (self.hashtagView.hidden) {
        [self updateHashtagViewMask];
        [self.hashtagView setHidden:NO];
        [self.hashtagView addSubview:self.horizontalView];
    } else {
        [self.hashtagView setHidden:YES];
        [self.horizontalView removeFromSuperview];
        self.horizontalView=nil;
    }
    
    [self updateHashtagButtonState:self.hashtagView.hidden];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendMsg];
    return NO;
}
-(void)sendMsg
{
    NSString * strInput=[self.txtInput.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([strInput length]==0) {
        return;
    }
 
    int msgIndex;
    NSString * deliveryDateStr=nil;
    if (!self.datePicker.hidden) {
        deliveryDateStr=[[MsgModel sharedInstance]getDefaultDateString:self.datePicker.date];
        [self.datePicker setHidden:YES];
        [self updateHashtagButtonState:YES];
        
        msgIndex=[[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_ME msg:[NSString stringWithFormat:@"%@ #date(%@)",strInput,deliveryDateStr] propagate:YES];
    } else {
        msgIndex=[[MsgModel sharedInstance]incomingMessage:OPERATOR_INDEX_ME msg:strInput propagate:YES];
    }
    
    
    if (msgIndex==-1) {
        return;
    }
    
    NSArray * msgData=[[[MsgModel sharedInstance]getMsgList]objectAtIndex:msgIndex];
    NSNumber * operatorIndex=[msgData objectAtIndex:0];
    NSNumber * timestamp=[msgData objectAtIndex:1];
    
    NSString * divID=[NSString stringWithFormat:@"%i-%lld",[operatorIndex intValue],[timestamp longLongValue]];
    UIWebView * webview=self.webView;
    
    [self.txtInput setText:@""];
    
    NSString * pairedUserID=[[MsgModel sharedInstance]getPairedUserID];
    if (pairedUserID!=nil) {
        
        NSDictionary * dict=nil;
        if (deliveryDateStr==nil) {
            dict=@{@"content_available": @YES,
                  // @"ios_badgeType": @"Increase",
                   @"mutable_content":@YES,
                   @"contents" : @{@"en": strInput},
                   @"include_player_ids": @[pairedUserID]
                   };
        } else {
            dict=@{@"content_available": @YES,
                   //@"ios_badgeType": @"Increase",
                   @"mutable_content":@YES,
                   @"contents" : @{@"en": strInput},
                   @"send_after":deliveryDateStr,
                   @"include_player_ids": @[pairedUserID]
                   };
        }

        
        
        [OneSignal postNotification:dict
                          onSuccess:^(NSDictionary *result) {
                              
                              
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  
                                  NSLog(@"OneSignal postNotification onSuccess");
                                  int newFlags=[[MsgModel sharedInstance]setMsgFlags:msgIndex flags:FLAGS_SENT];
                                  NSString * jsCall=[NSString stringWithFormat:@"setFlags('%@',%i);",divID,newFlags];
                                  [webview stringByEvaluatingJavaScriptFromString:jsCall];
                              });
                              

                              
                          } onFailure:^(NSError *error) {
                              NSLog(@"Error - %@", error.localizedDescription);
                              
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  int newFlags=[[MsgModel sharedInstance]setMsgFlags:msgIndex flags:FLAGS_ERROR];
                                  NSString * jsCall=[NSString stringWithFormat:@"setFlags('%@',%i);",divID,newFlags];
                                  [webview stringByEvaluatingJavaScriptFromString:jsCall];
                              });
                          }
         ];        
    }
    
}

- (IBAction)textFieldDone:(UITextField *)textField
{
    //
}

- (void)handleClear:(NSNotification *)paramNotification
{
    _lastMsgIndexAdded=-1;
    [self.webView stringByEvaluatingJavaScriptFromString:@"removeAllDivs();"];
}
- (void)handleBecomeActive:(NSNotification *)paramNotification
{
    NSArray * msgList=[[MsgModel sharedInstance]getMsgList];
    if ([msgList count]>0 && _lastMsgIndexAdded!=-1) {
        NSLog(@"handleBecomeActive msgList count %lu, _lastMsgIndexAdded %i, will add total %i",(unsigned long)[msgList count],_lastMsgIndexAdded,(int)([msgList count]-(_lastMsgIndexAdded+1)));
        [self addMessages:msgList startIndex:_lastMsgIndexAdded+1];
        _lastMsgIndexAdded=(int)([msgList count]-1);
    }
}
- (void)handleMsgAdded:(NSNotification *)paramNotification
{
    int msgIndex=[[paramNotification object]intValue];
    _lastMsgIndexAdded=msgIndex;
    
    NSArray * msgList=[[MsgModel sharedInstance]getMsgList];
    NSAssert([msgList count]>msgIndex, @"invalid index");
    
    NSArray * msgData=[msgList objectAtIndex:msgIndex];
    
    NSAssert([msgData count]>=4, @"invalid data size");
    NSNumber * operatorIndex=[msgData objectAtIndex:0];
    NSNumber * timestamp=[msgData objectAtIndex:1];
    NSNumber * flags=[msgData objectAtIndex:2];
    NSString * msg=[msgData objectAtIndex:3];
    NSDate * deliveryDate=([msgData count]>4?[msgData objectAtIndex:4]:nil);
    
    NSString * deliveryDateStr=@"";
    if (deliveryDate!=nil) {
        deliveryDateStr=[[MsgModel sharedInstance]getLocalizedDateString:deliveryDate];
    }
 
    NSString * jsCall=[NSString stringWithFormat:@"addDiv(%i,%lld,%i,'%@','%@');",[operatorIndex intValue],[timestamp longLongValue],[flags intValue], msg,deliveryDateStr];
    [self.webView stringByEvaluatingJavaScriptFromString:jsCall];
    
    if ([msg containsString:@"#shake"]) {
        [self shake];
        [self vibratePhone];
    }
}

- (void)vibratePhone;
{
    if([[UIDevice currentDevice].model isEqualToString:@"iPhone"])
    {
        AudioServicesPlaySystemSound (1352); //works ALWAYS as of this post
    }
    else
    {
        // Not an iPhone, so doesn't have vibrate
        // play the less annoying tick noise or one of your own
        AudioServicesPlayAlertSound (1105);
    }
}

-(void)shake
{
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:6];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.view center].x - 10.0f, [self.view center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.view center].x + 10.0f, [self.view center].y)]];
    [[self.view layer] addAnimation:animation forKey:@"position"];
}
- (void)handleKeyboardWillShow:(NSNotification *)paramNotification

{
    [self.sendNoKeyboardButton setHidden:YES];
    
    NSDictionary* info = [paramNotification userInfo];

    // size of the keyb that is about to appear
    CGSize kbSizeNew = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //make adjustments to constraints here...
    
    CGRect frame=self.view.superview.frame;
    frame.size.height-=kbSizeNew.height;
    [self.view setFrame:frame];
    
    //and here where's magick happen!
    
    [self.view layoutIfNeeded];
    
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollDown();"]];
    
}

- (void)handleKeyboardWillHide:(NSNotification *)paramNotification
{
    [self.sendNoKeyboardButton setHidden:NO];
    CGRect frame=self.view.superview.frame;
    [self.view setFrame:frame];
    [self.view layoutIfNeeded];
}


- (void)keyboardWasShown:(NSNotification*)aNotification
{

}
//called when the text field is being edited
- (IBAction)textFieldDidBeginEditing:(UITextField *)sender {
    sender.delegate = self;
}

- (IBAction)onButtonHashtags:(UIButton *)sender
{
    [self.datePicker setHidden:YES];
    [self triggerHashtags];
    [self.view layoutIfNeeded];
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollDown();"]];
}

- (IBAction)onButtonSend:(UIButton *)sender
{
    [self sendMsg];
}
- (IBAction)onButtonDate:(UIButton *)sender
{
    if (!self.hashtagView.hidden) {
        [self triggerHashtags];
    }
    //
    [self.datePicker setMinimumDate:[NSDate dateWithTimeIntervalSinceNow:60*2]];
    [self.datePicker setMaximumDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*30]];
    [self.datePicker setHidden:!self.datePicker.hidden];
    [self.view layoutIfNeeded];
    [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"scrollDown();"]];
    
}

-(void)updateHashtagButtonState:(BOOL)canOpenHashtags
{
    if (canOpenHashtags) {
        [self.hashtagShowButton setTitle: @"+" forState: UIControlStateNormal];
    } else {
        [self.hashtagShowButton setTitle: @"-" forState: UIControlStateNormal];
    }
}

- (void)setStatusBarBackgroundColor:(UIColor *)color {
    
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = color;
    }
}


- (void)viewDidLoad {
    //_keyboardVisible=NO;
    _lastMsgIndexAdded=-1;
    
    [super viewDidLoad];
    [self setStatusBarBackgroundColor:[UIColor whiteColor]];
    
    [self.datePicker setValue:[UIColor colorWithRed:70/255.0f green:161/255.0f blue:174/255.0f alpha:1.0f] forKeyPath:@"textColor"];
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    [invocation setArgument:&no atIndex:2];
    [invocation invokeWithTarget:self.datePicker];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleBecomeActive:) name:EVENT_BECOME_ACTIVE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleClear:) name:EVENT_CLEAR object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMsgAdded:) name:EVENT_INCOMING_MSG object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"webview" ofType:@"html"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    
    self.webView.delegate=self;
    self.webView.scalesPageToFit = YES;
    [self.webView loadHTMLString:fileContents baseURL:nil];
    
    [self.txtInput becomeFirstResponder];
}



- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSArray * msgDataList=[[MsgModel sharedInstance]getMsgList];
    NSLog(@"webViewDidFinishLoad msgList total elements %lu",(unsigned long)[msgDataList count]);
    [self addMessages:msgDataList startIndex:0];
    _lastMsgIndexAdded=(int)([msgDataList count]-1);
    
    if (![[MsgModel sharedInstance]getHasPermissions]) {
        [self alertPermissions];
    }
}


-(void)addMessages:(NSArray *)msgDataList startIndex:(int)startIndex
{
    NSMutableString * buffer=[NSMutableString stringWithFormat:@"addDivList(["];
    int totalMsg=(int)[msgDataList count];
    
    for (int i=startIndex;i<totalMsg;i++) {
        NSArray * msgData=[msgDataList objectAtIndex:i];
        NSAssert([msgData count]>=4, @"invalid length");
        
        NSNumber * operatorIndex=[msgData objectAtIndex:0];
        NSNumber * timestamp=[msgData objectAtIndex:1];
        NSNumber * flags=[msgData objectAtIndex:2];
        NSString * msg=[msgData objectAtIndex:3];
        NSDate * deliveryDate=([msgData count]>4?[msgData objectAtIndex:4]:nil);
        NSString * deliveryDateStr=@"";
        if (deliveryDate!=nil) {
            deliveryDateStr=[[MsgModel sharedInstance]getLocalizedDateString:deliveryDate];
        }
        [buffer appendFormat:@"%i,%lld,%i,'%@','%@'",[operatorIndex intValue],[timestamp longLongValue],[flags intValue],msg,deliveryDateStr];
        if (i<=[msgDataList count]-2) {
            [buffer appendString:@","];
        }
    }
    
    [buffer appendString:@"]);"];
    [self.webView stringByEvaluatingJavaScriptFromString:buffer];
}

-(void)updateHashtagViewMask
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGRect maskRect = self.hashtagView.frame;
    maskRect.size.height=[self getHeightInConstraint:self.hashtagView];
    maskRect.origin=CGPointMake(0, 0);
    
    // Create a path with the rectangle in it.
    CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
    
    // Set the path to the mask layer.
    maskLayer.path = path;
    
    // Release the path since it's not covered by ARC.
    CGPathRelease(path);
    
    // Set the mask of the view.
    self.hashtagView.layer.mask = maskLayer;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return false;
    }
    return true;
}

#pragma mark - Utility Methods

- (void)borderIsSelected:(BOOL)selected forView:(UIView *)view {
    UIImageView *borderView		= (UIImageView *)[view viewWithTag:BORDER_VIEW_TAG];
    NSString *borderImageName	= (selected) ? @"selected_border.png" : @"image_border.png";
    borderView.image			= [UIImage imageNamed:borderImageName];
}


#pragma mark - EasyTableViewDelegate

// These delegate methods support both example views - first delegate method creates the necessary views
- (UITableViewCell *)easyTableView:(EasyTableView *)easyTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"EasyTableViewCell";
    
    UITableViewCell *cell = [easyTableView.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    UILabel *label;
    
    if (cell == nil) {
        // Create a new table view cell
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.contentView.backgroundColor = CELL_BACKGROUND_COLOR;
        cell.backgroundColor = [UIColor blackColor];
        
        CGRect labelRect		= CGRectMake(10, 10, cell.contentView.frame.size.width-20, cell.contentView.frame.size.height-20);
        label        			= [[UILabel alloc] initWithFrame:labelRect];
        label.autoresizingMask  = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        label.textAlignment		= NSTextAlignmentCenter;
        label.textColor			= [UIColor whiteColor];
        label.font				= [UIFont boldSystemFontOfSize:16];
        
        // Use a different color for the two different examples
        //label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
   
        UIImageView *borderView		= [[UIImageView alloc] initWithFrame:label.bounds];
        borderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        borderView.tag				= BORDER_VIEW_TAG;
        
        [label addSubview:borderView];
        
        [cell.contentView addSubview:label];
    }
    else {
        label = cell.contentView.subviews[0];
    }
    
    switch (indexPath.row) {
        case 0: label.text=@"#h1"; break;
        case 1: label.text=@"#hr"; break;
        case 2: label.text=@"#bold"; break;
        case 3: label.text=@"#checklist"; break;
        case 4: label.text=@"#marquee"; break;
        case 5: label.text=@"#shake"; break;
        case 6: label.text=@"#hide"; break;
        case 7: label.text=@"#clear"; break;
        case 8: label.text=@"mycode"; break;
        default:
            break;
    }
    
    // selectedIndexPath can be nil so we need to test for that condition
    
    NSIndexPath * selectedIndexPath = _selectedHorizontalIndexPath;
    BOOL isSelected = selectedIndexPath ? ([selectedIndexPath compare:indexPath] == NSOrderedSame) : NO;
    [self borderIsSelected:isSelected forView:label];
    
    return cell;
}

// Optional delegate to track the selection of a particular cell

- (UIView *)viewForIndexPath:(NSIndexPath *)indexPath easyTableView:(EasyTableView *)tableView {
    UITableViewCell * cell	= [tableView.tableView cellForRowAtIndexPath:indexPath];
    return cell.contentView.subviews[0];
}

- (void)easyTableView:(EasyTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rowIndex=[indexPath row];
    if (rowIndex==0) {
        [self appendTag:@"#h1"];
    }
    if (rowIndex==1) {
        [self appendTag:@"#hr"];
    }
    if (rowIndex==2) {
        [self appendTag:@"#bold"];
    }
    if (rowIndex==3) {
        [self appendTag:@"#checklist"];
    }
    if (rowIndex==4) {
        [self appendTag:@"#marquee"];
    }
    if (rowIndex==5) {
        //
        [self appendTag:@"#shake"];
    }
    if (rowIndex==6) {
        //
        [self appendTag:@"#hide"];
    }
    if (rowIndex==7) {
        //
        [self appendTag:@"#clear"];
    }
    if (rowIndex==8) {
        //
        NSString * mycode=[[MsgModel sharedInstance]getUserID];
        NSString * opponent=[[MsgModel sharedInstance]getPairedUserID];
        NSString * jsCall=[NSString stringWithFormat:@"printCodes('%@','%@');",mycode,opponent];
        [self.webView stringByEvaluatingJavaScriptFromString:jsCall];
    }
}


-(void)appendTag:(NSString *)tagStr
{
    UITextField * txtInput=self.txtInput;
    if ([txtInput.text length]==0) {
        [txtInput setText:[txtInput.text stringByAppendingFormat:@" %@ ",tagStr]];
    } else {
        [txtInput setText:[txtInput.text stringByAppendingFormat:@" %@",tagStr]];
    }
}

// Delivers the number of cells in each section, this must be implemented if numberOfSectionsInEasyTableView is implemented
- (NSInteger)easyTableView:(EasyTableView *)easyTableView numberOfRowsInSection:(NSInteger)section {
    return NUM_OF_CELLS;
}




@end
