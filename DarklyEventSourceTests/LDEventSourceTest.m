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

@interface LDEventSource(Testable_LDEventSourceTest)
-(void)parseEventString:(NSString*)eventString;
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data;
@end

@interface LDEventSourceTest : XCTestCase

@end

@implementation LDEventSourceTest

- (void)testParseEventString {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testParseEventString.eventExpectation"];

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters

    NSURL *eventSourceUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:eventSourceUrl httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource parseEventString:putEventString];

    [self waitForExpectations:@[eventExpectation] timeout:1.0];
    [OHHTTPStubs removeAllStubs];
}

- (void)testEventSourceWithUrl {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[putEventString dataUsingEncoding:NSUTF8StringEncoding] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testEventSourceWithUrl.eventExpectation"];

    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [self waitForExpectations:@[eventExpectation] timeout:2.0];
    [OHHTTPStubs removeAllStubs];
}

-(void)testDidReceiveData_singleCall {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testDidReceiveData_singleCall.eventExpectation"];

    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertEqualObjects(event.data, putEventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectations:@[eventExpectation] timeout:2.0];
    [OHHTTPStubs removeAllStubs];
}

-(void)testDidReceiveData_multipleCalls_evenParts {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters
    NSArray *putEventStringParts = [putEventString splitIntoEqualParts:30];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testDidReceiveData_multipleCalls.eventExpectation"];

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

    [self waitForExpectations:@[eventExpectation] timeout:2.0];
    [OHHTTPStubs removeAllStubs];
}

-(void)testDidReceiveData_multipleCalls_randomParts {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSString *putEventData = [[putEventString componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters
    NSArray *putEventStringParts = [putEventString splitIntoPartsApproximatelySized:1024];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testDidReceiveData_multipleCalls.eventExpectation"];

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

    [self waitForExpectations:@[eventExpectation] timeout:2.0];
    [OHHTTPStubs removeAllStubs];
}

-(void)testDidReceiveData_extraNewLine {
    NSString *dummyClientStreamHost = @"dummy.clientstream.launchdarkly.com";

    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSMutableArray *putEventStringParts = [NSMutableArray arrayWithArray:[putEventString componentsSeparatedByString:@":\""]];
    NSUInteger selectedIndex = arc4random_uniform((uint32_t)putEventStringParts.count - 1) + 1;
    putEventStringParts[selectedIndex] = [NSString stringWithFormat:@"\n\n%@", putEventStringParts[selectedIndex]];
    NSString *putEventStringWithExtraNewLine = [putEventStringParts componentsJoinedByString:@":\""];
    NSString *putEventData = [[putEventStringWithExtraNewLine componentsSeparatedByString:@"data:"] lastObject];
    putEventData = [putEventData substringToIndex:putEventData.length - 2]; //chop off the last 2 characters

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:dummyClientStreamHost];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        return [OHHTTPStubsResponse responseWithData:[NSData data] statusCode:200 headers:nil];
    }];

    XCTestExpectation *eventExpectation = [self expectationWithDescription:@"LDEventSourceTest.testDidReceiveData_extraNewLine.eventExpectation"];

    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.event, @"put");
        XCTAssertTrue([putEventData hasPrefix:event.data]);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventStringWithExtraNewLine dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectations:@[eventExpectation] timeout:2.0];
    [OHHTTPStubs removeAllStubs];
}

@end
