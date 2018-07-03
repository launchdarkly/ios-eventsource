//
//  LDEventSourceTest.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 LaunchDarkly. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "LDEventSource.h"
#import "LDEventSource+Testable.h"
#import "NSString+Testable.h"

@interface NSString(LDEventSourceTest)
@property (nonatomic, readonly, copy) NSString *eventDataString;
@end

@implementation NSString(LDEventSourceTest)
-(NSString*)eventDataString {
    NSString *eventData = [[self componentsSeparatedByString:@"data:"] lastObject];
    eventData = [eventData substringToIndex:eventData.length - 2]; //chop off the last 2 characters
    return eventData;
}
@end

@interface LDEventSource(Testable_LDEventSourceTest)
-(void)parseEventString:(NSString*)eventString;
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
@end

NSString * const dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

@interface LDEventSourceTest : XCTestCase

@end

@implementation LDEventSourceTest

-(XCTestExpectation*)expectationWithMethodName:(NSString*)methodName expectationName:(NSString*)expectationName {
    return [self expectationWithDescription:[NSString stringWithFormat:@"%@.%@.%@", NSStringFromClass([self class]), methodName, expectationName]];
}

-(void)stubResponseWithData:(NSData*)data {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];
}

-(void)tearDown {
    [OHHTTPStubs removeAllStubs];

    [super tearDown];
}

- (void)testParseEventString {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = putEventString.eventDataString;
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource parseEventString:putEventString];

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

- (void)testEventSourceWithUrl {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = putEventString.eventDataString;
    [self stubResponseWithData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

-(void)testDidReceiveData_singleCall {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = putEventString.eventDataString;
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

-(void)testDidReceiveData_multipleCalls_evenParts {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = putEventString.eventDataString;
    NSArray *putEventStringParts = [putEventString splitIntoEqualParts:30];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    for (NSString *eventStringPart in putEventStringParts) {
        [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventStringPart dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

-(void)testDidReceiveData_multipleCalls_randomParts {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = putEventString.eventDataString;
    NSArray *putEventStringParts = [putEventString splitIntoPartsApproximatelySized:1024];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    for (NSString *eventStringPart in putEventStringParts) {
        [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventStringPart dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

-(void)testDidReceiveData_extraNewLine {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSMutableArray *putEventStringParts = [NSMutableArray arrayWithArray:[putEventString componentsSeparatedByString:@":\""]];
    NSUInteger selectedIndex = arc4random_uniform((uint32_t)putEventStringParts.count - 1) + 1;
    putEventStringParts[selectedIndex] = [NSString stringWithFormat:@"\n\n%@", putEventStringParts[selectedIndex]];
    NSString *putEventStringWithExtraNewLine = [putEventStringParts componentsJoinedByString:@":\""];
    NSString *putEventData = putEventStringWithExtraNewLine.eventDataString;
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertTrue([putEventData hasPrefix:event.data]);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventStringWithExtraNewLine dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

@end
