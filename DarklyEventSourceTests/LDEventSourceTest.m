//
//  LDEventSourceTest.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "LDEventSource.h"
#import "LDEventSource+Testable.h"
#import "NSString+LDEventSource.h"
#import "NSString+Testable.h"
#import "NSString+LDEvent+Testable.h"

@interface LDEventSource(Testable_LDEventSourceTest)
@property (nonatomic, assign) NSTimeInterval retryInterval;

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
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource parseEventString:putEventString];

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

- (void)testOpen {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    [self stubResponseWithData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);
        XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
    }];

    [eventSource open];
}

- (void)testOpen_backgroundThread {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    [self stubResponseWithData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];

    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);
        XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
        [eventExpectation fulfill];
    }];

    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.launchDarkly.test.eventSource.openOnBackgroundThread", DISPATCH_QUEUE_SERIAL);
    dispatch_async(backgroundQueue, ^{
        [eventSource open];
    });

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
}

-(void)testDidReceiveData_singleCall {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventString dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

-(void)testDidReceiveData_multipleCalls_evenParts {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSArray *putEventStringParts = [putEventString splitIntoEqualParts:30];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    for (NSString *eventStringPart in putEventStringParts) {
        [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventStringPart dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

-(void)testDidReceiveData_multipleCalls_randomParts {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSArray *putEventStringParts = [putEventString splitIntoPartsApproximatelySized:1024];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    for (NSString *eventStringPart in putEventStringParts) {
        [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventStringPart dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

-(void)testDidReceiveData_extraNewLine {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSMutableArray *putEventStringParts = [NSMutableArray arrayWithArray:[putEventString componentsSeparatedByString:@":\""]];
    NSUInteger selectedIndex = arc4random_uniform((uint32_t)putEventStringParts.count - 1) + 1;
    putEventStringParts[selectedIndex] = [NSString stringWithFormat:@"\n\n%@", putEventStringParts[selectedIndex]];
    NSString *putEventStringWithExtraNewLine = [putEventStringParts componentsJoinedByString:@":\""];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    NSTimeInterval originalRetryInterval = eventSource.retryInterval;
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertTrue([putEventStringWithExtraNewLine.eventData hasPrefix:event.data]);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[putEventStringWithExtraNewLine dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, originalRetryInterval);     //No change because retry is after the extra newline
}

-(void)testDidReceiveData_extraSpaces {
    NSString *eventString = [NSString stringFromFileNamed:@"testEventWithSpaces"];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    LDEventSource *eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, eventString.eventId);
        XCTAssertEqualObjects(event.event, eventString.eventEvent);
        XCTAssertEqualObjects(event.data, eventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventString dataUsingEncoding:NSUTF8StringEncoding]];

    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [eventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

-(void)testDidReceiveData_multipleThreads {
    NSString *putEventString = [NSString stringFromFileNamed:@"largePutEvent"];
    NSArray *putEventStringParts = [putEventString splitIntoEqualParts:30];
    [self stubResponseWithData:[NSData data]];
    __block XCTestExpectation *eventExpectation = [self expectationWithMethodName:NSStringFromSelector(_cmd) expectationName:@"eventExpectation"];
    dispatch_queue_t eventSourceQueue = dispatch_queue_create("com.launchdarkly.test.didReceiveData.multipleThreads.eventSource", DISPATCH_QUEUE_SERIAL);
    __block LDEventSource *eventSource;
    dispatch_sync(eventSourceQueue, ^{
        eventSource = [LDEventSource eventSourceWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", dummyClientStreamHost]] httpHeaders:nil];
    });

    [eventSource onMessage:^(LDEvent *event) {
        XCTAssertNotNil(event);
        XCTAssertEqualObjects(event.id, putEventString.eventId);
        XCTAssertEqualObjects(event.event, putEventString.eventEvent);
        XCTAssertEqualObjects(event.data, putEventString.eventData);
        XCTAssertEqual(event.readyState, kEventStateOpen);

        [eventExpectation fulfill];
    }];

    NSInteger partCount = 0;
    for (NSString *eventStringPart in putEventStringParts) {
        partCount++;
        NSString *eventStringPartCopy = [eventStringPart copy];
        dispatch_async(eventSourceQueue, ^{
            [eventSource URLSession:eventSource.session dataTask:eventSource.eventSourceTask didReceiveData:[eventStringPartCopy dataUsingEncoding:NSUTF8StringEncoding]];
        });
    }

    [self waitForExpectationsWithTimeout:10.0 handler:^(NSError * _Nullable error) {
        eventExpectation = nil;
    }];
    XCTAssertEqual(eventSource.retryInterval, [putEventString.eventRetry integerValue] / MILLISEC_PER_SEC);
}

@end
