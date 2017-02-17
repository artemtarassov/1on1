//
//  MsgModel.h
//  1on1
//
//  Created by Artem Tarassov on 01/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//
#import <foundation/Foundation.h>

#define EVENT_UPDATE_USERID @"updateUserID"
#define EVENT_INCOMING_MSG @"incomingMsg"
#define EVENT_PAIR_REQUEST @"pairRequest"
#define EVENT_PAIR_CONFIRMED @"pairConfirmed"
#define EVENT_ALERT_PERMISSIONS @"alertPermissions"
#define EVENT_CLEAR @"clearRequest"
#define EVENT_BECOME_ACTIVE @"becomeActive"

#define OPERATOR_INDEX_ME 10
#define OPERATOR_INDEX_OPPONENT 20

#define FLAGS_DEFAULT 1     //0001 //2^0
#define FLAGS_SENT 2        //0010 //2^1
#define FLAGS_ERROR 4       //0100 //2^2
#define FLAGS_PROPAGATED 8  //1000 //2^3

@interface MsgModel : NSObject {
    BOOL _perm;
}
@property (nonatomic, retain) NSUserDefaults * sharedDefaults;

+ (id)sharedInstance;
-(void)applicationDidBecomeActive;
-(NSString*)removeDateFromMessage:(NSString *)string;
-(NSString *)getDefaultDateString:(NSDate *)date;
-(NSString *)getLocalizedDateString:(NSDate *)date;
-(void)setHasPermissions:(BOOL)perm;
-(BOOL)getHasPermissions;
-(NSDate *)fetchDateFromMessage:(NSString *)string;

-(int)setMsgFlags:(int)msgIndex flags:(int)flags;
-(void)removeAllMessages;
-(NSString *)getPairConfirmedUserID;
-(void)removePairConfirmed;
-(void)removePairRequest;
-(int)incomingMessage:(int)operatorIndex msg:(NSString *)msg propagate:(BOOL)propagate;
-(NSMutableArray *)getMsgList;
-(NSString *)getPairRequestUserID;

-(NSString *)getPairedUserID;
-(NSString *)getUserID;
-(NSArray *)getLastMsg;//0=NSNumber with operator, 1=nsnumber with timestamp, 2=flags, 3=msg

-(void)setPairedUserID:(NSString *)uid;
-(void)setUserID:(NSString *)uid;

@end
