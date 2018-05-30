//
//  LDEventParser.h
//  DarklyEventSource
//
//  Created by Mark Pokorny on 5/30/18. +JMJ
//  Copyright © 2018 Neil Cowburn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDEvent;

@interface LDEventParser : NSObject
@property (nonatomic, assign) NSTimeInterval foundRetryInterval;
@property (nonatomic, copy) NSString *remainingEventString;

-(LDEvent*)eventFromString:(NSString*)eventString;
@end
