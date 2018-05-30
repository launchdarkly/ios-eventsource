//
//  LDDataAccumulator.m
//  DarklyEventSource
//
//  Created by Mark Pokorny on 5/30/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import "LDDataAccumulator.h"

@implementation LDDataAccumulator
-(void)accumulateDataWithString:(NSString*)dataString {
    if (dataString.length == 0) { return; }
    if (self.dataString == nil) {
        self.dataString = dataString;
        return;
    }
    self.dataString = [self.dataString stringByAppendingString:dataString];
}

-(BOOL)isReadyToParseEvent {
    if (self.dataString.length == 0) { return NO; }
    NSArray<NSString*> *lines = [self.dataString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if (lines.count == 0) { return NO; }
    return [lines lastObject].length == 0;
}

-(void)reset {
    self.dataString = nil;
}
@end
