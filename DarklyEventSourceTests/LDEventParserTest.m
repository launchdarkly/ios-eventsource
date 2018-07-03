//
//  LDEventParserTest.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "LDEventSource.h"
#import "LDEventParser.h"
#import "NSString+Testable.h"

@interface LDEventParserTest : XCTestCase

@end

@implementation LDEventParserTest

-(void)testParseString {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters: \n\n
    LDEventParser *parser = [LDEventParser eventParserWithEventString:putEventString];
    LDEvent *event = parser.event;

    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.event, @"put");
    XCTAssertEqualObjects(event.data, putEventData);
    XCTAssertEqual(event.readyState, kEventStateOpen);
    XCTAssertNil(parser.remainingEventString);
    XCTAssertNil(parser.retryInterval);
}
@end
