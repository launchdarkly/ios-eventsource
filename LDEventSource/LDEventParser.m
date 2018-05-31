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
#import "NSString+LDEventSource.h"
#import "NSArray+LDEventSource.h"

static NSString *const ESKeyValueDelimiter = @":";

static NSString *const LDEventDataKey = @"data";
static NSString *const LDEventIDKey = @"id";
static NSString *const LDEventEventKey = @"event";
static NSString *const LDEventRetryKey = @"retry";

@interface LDEventParser()
@property (nonatomic, copy) NSString *eventString;
@property (nonatomic, strong) LDEvent *event;
@property (nonatomic, strong) NSNumber *retryInterval;
@property (nonatomic, copy) NSString *remainingEventString;
@end

@implementation LDEventParser
+(instancetype)eventParserWithEventString:(NSString*)eventString {
    return [[LDEventParser alloc] initWithEventString:eventString];
}

-(instancetype)initWithEventString:(NSString*)eventString {
    if (!(self = [super init])) { return nil; }

    self.eventString = eventString;
    [self parseEventString];

    return self;
}

-(void)parseEventString {
    if (self.eventString.length == 0) { return; }

    NSArray<NSString*> *linesToParse = [self linesToParseFromEventString];
    self.remainingEventString = [self remainingEventStringAfterParsingEventString];
    if (linesToParse.count == 0) { return; }

    LDEvent *event = [LDEvent new];
    event.readyState = kEventStateOpen;

    for (NSString *line in linesToParse) {
        if ([line hasPrefix:ESKeyValueDelimiter]) {
            continue;
        }

        if (line.length == 0) {
            self.event = event;
            return;
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
                    if ([value isKindOfClass:[NSNumber class]]) {
                        self.retryInterval = @([value doubleValue]);
                    }
                }
            }
        }
    }
}

//extracts lines from the first thru the first empty line
-(nullable NSArray<NSString*>*)linesToParseFromEventString {
    if (self.eventString.length == 0) { return nil; }

    NSArray<NSString*> *lines = [self.eventString lines];
    NSUInteger indexOfFirstEmptyLine = [lines indexOfFirstEmptyLine];
    if (indexOfFirstEmptyLine == NSNotFound) { return nil; }

    NSArray<NSString*> *linesToParse = [lines subarrayWithRange:NSMakeRange(0, indexOfFirstEmptyLine + 1)];
    if (linesToParse.count == 0) { return nil; }

    return linesToParse;
}

-(NSString*)remainingEventStringAfterParsingEventString {
    if (self.eventString.length == 0) { return nil; }

    NSArray<NSString*> *lines = [self.eventString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSUInteger indexOfFirstEmptyLine =  [lines indexOfObject:@""];
    if (indexOfFirstEmptyLine == NSNotFound) { return [self.eventString copy]; }
    if (indexOfFirstEmptyLine >= lines.count - 1) { return nil; }

    NSArray<NSString*> *remainingLines = [lines subarrayWithRange:NSMakeRange(indexOfFirstEmptyLine + 1, lines.count - indexOfFirstEmptyLine - 1)];
    NSString *remainingEventString = @"";
    NSPredicate *nonemptyLinePredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (![evaluatedObject isKindOfClass:[NSString class]]) { return NO; }
        NSString *evaluatedString = evaluatedObject;
        return evaluatedString.length > 0;
    }];
    NSArray<NSString*> *nonEmptyRemainingLines = [remainingLines filteredArrayUsingPredicate:nonemptyLinePredicate];
    if (nonEmptyRemainingLines.count == 0) { return nil; }

    remainingEventString = [nonEmptyRemainingLines componentsJoinedByString:@"\n"];
    return remainingEventString;
}
@end
