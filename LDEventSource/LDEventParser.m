//
//  LDEventParser.m
//  DarklyEventSource
//
//  Created by Mark Pokorny on 5/30/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDEventParser.h"
#import "LDEventSource.h"

static NSString *const ESKeyValueDelimiter = @":";

static NSString *const LDEventDataKey = @"data";
static NSString *const LDEventIDKey = @"id";
static NSString *const LDEventEventKey = @"event";
static NSString *const LDEventRetryKey = @"retry";

@implementation LDEventParser
-(LDEvent*)eventFromString:(NSString*)eventString {
    self.foundRetryInterval = 0.0;
    self.remainingEventString = @"";

    NSArray<NSString*> *lines = [eventString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    LDEvent *event = [LDEvent new];
    event.readyState = kEventStateOpen;

    BOOL eventCompleted = NO;
    for (NSString *line in lines) {
        if ([line hasPrefix:ESKeyValueDelimiter]) {
            continue;
        }

        if (eventCompleted) {
            if (line.length == 0) { continue; }
            NSString *lineSeparator = self.remainingEventString.length > 0 ? @"\n" : @"";
            self.remainingEventString = [self.remainingEventString stringByAppendingFormat:@"%@%@", lineSeparator, line];
            continue;
        }

        if (line.length == 0) {
            eventCompleted = YES;
            continue;
        }

        @autoreleasepool {
            NSScanner *scanner = [NSScanner scannerWithString:line];
            scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];

            NSString *key, *value;
            [scanner scanUpToString:ESKeyValueDelimiter intoString:&key];
            [scanner scanString:ESKeyValueDelimiter intoString:nil];
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&value];

            if (key && value) {
                if ([key isEqualToString:LDEventEventKey]) {
                    event.event = value;
                } else if ([key isEqualToString:LDEventDataKey]) {
                    if (event.data != nil) {
                        event.data = [event.data stringByAppendingFormat:@"\n%@", value];
                    } else {
                        event.data = value;
                    }
                } else if ([key isEqualToString:LDEventIDKey]) {
                    event.id = value;
                } else if ([key isEqualToString:LDEventRetryKey]) {
                    self.foundRetryInterval = [value doubleValue];
                }
            }
        }
    }
    if (self.remainingEventString.length == 0) {
        self.remainingEventString = nil;
    }
    return event;
}
@end
