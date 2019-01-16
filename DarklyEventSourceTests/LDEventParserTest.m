//
//  LDEventParserTest.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "LDEventSource.h"
#import "LDEventParser.h"
#import "NSString+LDEventSource.h"
#import "NSString+Testable.h"
#import "NSString+LDEvent+Testable.h"

@interface LDEventParserTest : XCTestCase

@end

@implementation LDEventParserTest

-(void)testParseString {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    LDEventParser *parser = [LDEventParser eventParserWithEventString:putEventString];
    LDEvent *event = parser.event;

    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.id, putEventString.eventId);          //largePutEvent
    XCTAssertEqualObjects(event.event, putEventString.eventEvent);    //put
    XCTAssertEqualObjects(event.data, putEventString.eventData);      //too long for here!!
    XCTAssertEqual(event.readyState, kEventStateOpen);
    XCTAssertNil(parser.remainingEventString);
    XCTAssertEqualObjects(parser.retryInterval, @([putEventString.eventRetry integerValue] / MILLISEC_PER_SEC));   //5.0
}

-(void)testParseString_badRetry {
    NSString *putEventString = [NSString stringFromFileNamed:@"putEvent_badRetry"];
    LDEventParser *parser = [LDEventParser eventParserWithEventString:putEventString];
    LDEvent *event = parser.event;

    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.id, putEventString.eventId);            //putEvent_badRetry
    XCTAssertEqualObjects(event.event, [putEventString eventEvent]);    //put
    XCTAssertEqualObjects(event.data, [putEventString eventData]);      //see fixture
    XCTAssertEqual(event.readyState, kEventStateOpen);
    XCTAssertNil(parser.remainingEventString);
    XCTAssertNil(parser.retryInterval);
}

-(void)testHasEventTerminator_shortString {
    NSString *eventString = nil;
    XCTAssertFalse(eventString.hasEventTerminator);
    eventString = @"";
    XCTAssertFalse(eventString.hasEventTerminator);
    eventString = @"\n";
    XCTAssertFalse(eventString.hasEventTerminator);
    eventString = @"\n\0";
    XCTAssertFalse(eventString.hasEventTerminator);
    eventString = @"\n\n";
    XCTAssertTrue(eventString.hasEventTerminator);
}
@end
