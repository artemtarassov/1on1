//
//  MsgModel.m
//  1on1
//
//  Created by Artem Tarassov on 01/02/2017.
//  Copyright © 2017 t3soft. All rights reserved.
//
#import "MsgModel.h"

#define MAX_MESSAGES_IN_CACHE 256

@implementation MsgModel

@synthesize sharedDefaults;

+ (id)sharedInstance {
    static MsgModel *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        sharedDefaults=[[NSUserDefaults standardUserDefaults] initWithSuiteName:@"group.com.artjom.1on1appgroup"];
        
        NSMutableArray * existingMsgList=[self getMsgList];
        while ([existingMsgList count]>MAX_MESSAGES_IN_CACHE) {
            [existingMsgList removeObjectAtIndex:0];
        }
        [sharedDefaults setObject:existingMsgList forKey:@"msg"];
        _perm=NO;
        //[self removeAllMessages];
    }
    return self;
}
-(void)applicationDidBecomeActive
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_BECOME_ACTIVE object:self];
    });
}
-(void)setHasPermissions:(BOOL)perm
{
    if (_perm!=perm) {
        _perm=perm;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_ALERT_PERMISSIONS object:self];
        });
    }
}
-(BOOL)getHasPermissions
{
    return _perm;
}
-(void)removeAllMessages
{
    [sharedDefaults removeObjectForKey:@"msg"];
    [sharedDefaults synchronize];
}
-(void)setPairedUserID:(NSString *)uid
{
    NSLog(@"MsgModel setPairedUserID %@",uid);
    [sharedDefaults setObject:uid forKey:@"pairedUser"];
    [sharedDefaults synchronize];
}
-(void)setUserID:(NSString *)uid
{
    NSLog(@"MsgModel setUserID %@",uid);
    [sharedDefaults setObject:uid forKey:@"myUser"];
    [sharedDefaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_UPDATE_USERID object:self];
    });
}

-(NSString *)getPairedUserID
{
    return [sharedDefaults stringForKey:@"pairedUser"];
}
-(NSString *)getUserID
{
    return [sharedDefaults stringForKey:@"myUser"];
}
-(NSArray *)getLastMsg
{
    NSArray * existingMsgList=[sharedDefaults arrayForKey:@"msg"];
    if (existingMsgList==nil) {
        return nil;
    }
    NSArray * list=[existingMsgList objectAtIndex:[existingMsgList count]-1];
    return list;
}


-(NSString *)getPairConfirmedUserID
{
    return [sharedDefaults stringForKey:@"pairConfirmedUserId"];
}


-(NSString *)getPairRequestUserID
{
    return [sharedDefaults stringForKey:@"pairRequestUserId"];
}

-(void)removePairRequest
{
    [sharedDefaults removeObjectForKey:@"pairRequestUserId"];
    [sharedDefaults synchronize];
}
-(void)removePairConfirmed
{
    [sharedDefaults removeObjectForKey:@"pairConfirmedUserId"];
    [sharedDefaults synchronize];
}

-(NSMutableArray *)getMsgList
{
    NSArray * existingMsgList=[sharedDefaults arrayForKey:@"msg"];
    NSMutableArray * result=[NSMutableArray array];
    if (existingMsgList==nil || [existingMsgList count]==0) {
        //
    } else {
        [result addObjectsFromArray:existingMsgList];
    }
    return result;
}

-(int)setMsgFlags:(int)msgIndex flags:(int)fl
{
    NSMutableArray * msgList=[NSMutableArray arrayWithArray:[self getMsgList]];
    NSArray * prevMsgData=[msgList objectAtIndex:msgIndex];
    NSMutableArray * newMsgData=[NSMutableArray array];
    [newMsgData addObject:[prevMsgData objectAtIndex:0]];
    [newMsgData addObject:[prevMsgData objectAtIndex:1]];
    int prevFlags=[[prevMsgData objectAtIndex:2]intValue];
    int newFlags=fl|prevFlags;
    [newMsgData addObject:[NSNumber numberWithInt:newFlags]];
    [newMsgData addObject:[prevMsgData objectAtIndex:3]];
    if ([prevMsgData count]>4) {//delivery date
        [newMsgData addObject:[prevMsgData objectAtIndex:4]];
    }
    
    [msgList replaceObjectAtIndex:msgIndex withObject:newMsgData];
    [sharedDefaults setObject:msgList forKey:@"msg"];
    [sharedDefaults synchronize];
    NSLog(@"setMsgFlags %i = %i for operator %i",msgIndex,fl,[[newMsgData objectAtIndex:0]intValue]);
    
    return newFlags;
}



-(NSString *)fetchDateStringFromMessage:(NSString *)string
{
    NSRange searchFromRange = [string rangeOfString:@"#date("];
    if (searchFromRange.length==0) {
        return nil;
    }
    NSRange searchToRange = [string rangeOfString:@")"
                                          options:NSLiteralSearch
                                            range:NSMakeRange(searchFromRange.location, [string length]-searchFromRange.location)];
    if (searchToRange.location==0) {
        return nil;
    }
    NSString *substring = [string substringWithRange:NSMakeRange(searchFromRange.location+searchFromRange.length, searchToRange.location-searchFromRange.location-searchFromRange.length)];
    return substring;
}

-(NSDate *)fetchDateFromMessage:(NSString *)string
{
    NSString *substring = [self fetchDateStringFromMessage:string];
    if (substring==nil) {
        return nil;
    }
    return [self getDateFromString:substring];
}

-(NSDate *)getDateFromString:(NSString *)dateStr
{
    //"2015-09-24 14:00:00 GMT-0700"
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    return [dateFormatter dateFromString:dateStr];
}

-(NSString *)getDefaultDateString:(NSDate *)date
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    return [dateFormatter stringFromDate:date];
}

-(NSString *)getLocalizedDateString:(NSDate *)date
{
    return [NSDateFormatter localizedStringFromDate:date
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterShortStyle];
}

-(NSString*)removeDateFromMessage:(NSString *)string
{
    NSString *rawDateStr=[self fetchDateStringFromMessage:string];
    if (rawDateStr==nil) {
        return string;
    }
    NSString * substring = [NSString stringWithFormat:@"#date(%@)",rawDateStr];
    return [string stringByReplacingOccurrencesOfString:substring withString:@""];
}


-(NSString *)fetchUserIdFromMessage:(NSString *)string
{
    NSRange searchFromRange = [string rangeOfString:@"("];
    NSRange searchToRange = [string rangeOfString:@")"];
    NSString *substring = [string substringWithRange:NSMakeRange(searchFromRange.location+searchFromRange.length, searchToRange.location-searchFromRange.location-searchFromRange.length)];
    return substring;
}

-(int)incomingMessage:(int)operatorIndex msg:(NSString *)msg propagate:(BOOL)propagate
{
    NSLog(@"MsgModel incomingMessage(%i) %@, propagate %i",operatorIndex, msg, propagate);
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    
    if (msg==nil || [msg length]==0) {
        return -1;
    }
    
    NSMutableArray * existingMsgList=[self getMsgList];
    
    if ([existingMsgList count]>0) {
        NSArray * lastMsgData=(NSArray *)[existingMsgList lastObject];
        
        NSNumber * lastOperatorIndex=[lastMsgData objectAtIndex:0];
        NSNumber * lastTimestamp=[lastMsgData objectAtIndex:1];
        NSNumber * lastFlags=[lastMsgData objectAtIndex:2];
        NSString * lastMsg=[lastMsgData objectAtIndex:3];
        
        NSLog(@"MsgModel lastOperatorIndex %i, lastFlags %i",[lastOperatorIndex intValue],[lastFlags intValue]);
        
        BOOL sameMsg=[lastMsg isEqualToString:msg];
        BOOL sameOP=[lastOperatorIndex intValue]==operatorIndex;
        BOOL sameTime=((long long)[lastTimestamp doubleValue]-(long long)timeStamp)<1;
        
        NSLog(@"MsgModel incomingMessage sameMsg %i, sameOP %i, sameTime %i",sameMsg,sameOP,sameTime);
        
        if (sameMsg && sameOP) {
            
            bool didPropagate=([lastFlags intValue]&FLAGS_PROPAGATED)==FLAGS_PROPAGATED;
            if (!didPropagate && propagate) {
                int msgIndex=(int)[existingMsgList count]-1;
                [self setMsgFlags:msgIndex flags:FLAGS_PROPAGATED];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_INCOMING_MSG object:[NSNumber numberWithInt:msgIndex]];
                });
            }
            return -1;
        }
    }
  
    
    {
        NSString * str2search=@"Pair Request (";
        if ([msg containsString:str2search]) {
            NSString * opponentUID=[self fetchUserIdFromMessage:msg];
            [sharedDefaults setObject:opponentUID forKey:@"pairRequestUserId"];
            [sharedDefaults synchronize];
            
            if (propagate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_PAIR_REQUEST object:self];
                });
            }

            
            
            return -1;
        }
    }
    
    {
        NSString * str2search=@"Pair Confirmed (";
        if ([msg containsString:str2search]) {
            NSString * opponentUID=[self fetchUserIdFromMessage:msg];
            [sharedDefaults setObject:opponentUID forKey:@"pairConfirmedUserId"];
            [sharedDefaults synchronize];
            
            if (propagate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_PAIR_CONFIRMED object:self];
                });
            }

            return -1;
        }
    }
    
    {
        NSString * str2search=@"#clear";
        if ([msg containsString:str2search]) {
            [sharedDefaults setObject:[NSMutableArray array] forKey:@"msg"];
            [sharedDefaults synchronize];
            if (propagate) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_CLEAR object:nil];
                });
            }
 
        }
    }
    
    NSMutableArray * result=[NSMutableArray array];
    if (existingMsgList==nil || [existingMsgList count]==0) {
        //
    } else {
        [result addObjectsFromArray:existingMsgList];
    }
    
    NSNumber *timeStampObj = [NSNumber numberWithLongLong:timeStamp*1000];
    NSNumber *flags=[NSNumber numberWithInt:FLAGS_DEFAULT];
    NSNumber * op=[NSNumber numberWithInt:operatorIndex];
    NSDate * deliveryDate=[self fetchDateFromMessage:msg];
    if (deliveryDate!=nil) {
        msg=[self removeDateFromMessage:msg];
        [result addObject:[NSArray arrayWithObjects:op,timeStampObj,flags,msg,deliveryDate,nil]];
    } else {
        [result addObject:[NSArray arrayWithObjects:op,timeStampObj,flags,msg,nil]];
    }
    
    [sharedDefaults setObject:result forKey:@"msg"];
    [sharedDefaults synchronize];
    
    int msgIndex=(int)[result count]-1;
    
    if (propagate) {
        [self setMsgFlags:msgIndex flags:FLAGS_PROPAGATED];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]postNotificationName:EVENT_INCOMING_MSG object:[NSNumber numberWithInt:msgIndex]];
        });
    }
    
    return msgIndex;
}


@end
