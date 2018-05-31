//
//  NSArray+LDEventSource.m
//  DarklyEventSource
//
//  Created by Mark Pokorny on 5/31/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray+LDEventSource.h"

@implementation NSArray(LDEventSource)
-(NSUInteger)indexOfFirstEmptyLine {
    if (![self.firstObject isKindOfClass:[NSString class]]) { return NSNotFound; }
    return [self indexOfObject:@""];
}
@end
