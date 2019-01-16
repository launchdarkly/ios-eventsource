//
//  NSString+LDEvent+Testable.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 1/16/19. +JMJ
//  Copyright © 2019 Catamorphic Co. All rights reserved.
//

#import "NSString+LDEvent+Testable.h"
#import "NSString+LDEventSource.h"

@implementation NSString (LDEvent_Testable)
-(NSString*)eventId  {
    NSString* prefix = [NSString prefixWithTag:LDEventKeyId];
    return [[self lineStartingWith:prefix] omittingPrefix:prefix];
}

-(NSString*)eventEvent  {
    NSString* prefix = [NSString prefixWithTag:LDEventKeyEvent];
    return [[self lineStartingWith:prefix] omittingPrefix:prefix];
}

-(NSString*)eventData {
    NSString* prefix = [NSString prefixWithTag:LDEventKeyData];
    return [[self lineStartingWith:prefix] omittingPrefix:prefix];
}

-(NSString*)eventRetry {
    NSString* prefix = [NSString prefixWithTag:LDEventKeyRetry];
    return [[self lineStartingWith:prefix] omittingPrefix:prefix];
}

+(NSString*)prefixWithTag:(NSString*)tag {
    return [tag stringByAppendingString:LDEventSourceKeyValueDelimiter];
}

-(NSString*)lineStartingWith:(NSString*)prefix {
    NSPredicate *prefixPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (evaluatedObject == nil || ![evaluatedObject isKindOfClass:[NSString class]]) {
            return NO;
        }
        NSString *evaluatedString = evaluatedObject;
        return [evaluatedString hasPrefix:prefix];
    }];
    return [[[self lines] filteredArrayUsingPredicate:prefixPredicate] firstObject];
}

-(NSString*)omittingPrefix:(NSString*)prefix {
    return [[self stringByReplacingOccurrencesOfString:prefix withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
@end
