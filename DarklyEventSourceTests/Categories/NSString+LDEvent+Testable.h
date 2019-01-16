//
//  NSString+LDEvent+Testable.h
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 1/16/19. +JMJ
//  Copyright © 2019 Catamorphic Co. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const LDEventSourceKeyValueDelimiter;
extern NSString *const LDEventKeyId;
extern NSString *const LDEventKeyEvent;
extern NSString *const LDEventKeyData;
extern NSString *const LDEventKeyRetry;
extern double MILLISEC_PER_SEC;

@interface NSString (LDEvent_Testable)
@property (nonatomic, strong, readonly, nullable) NSString *eventId;
@property (nonatomic, strong, readonly, nullable) NSString *eventEvent;
@property (nonatomic, strong, readonly, nullable) NSString *eventData;
@property (nonatomic, strong, readonly, nullable) NSString *eventRetry;
@end

NS_ASSUME_NONNULL_END
