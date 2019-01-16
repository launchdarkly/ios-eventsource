//
//  LDEventSource+Testable.h
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDEventSource.h"
#import "LDEventStringAccumulator.h"

@interface LDEventSource(Testable)
@property (nonatomic, strong) NSURLSessionDataTask *eventSourceTask;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) LDEventStringAccumulator *eventStringAccumulator;

@end
