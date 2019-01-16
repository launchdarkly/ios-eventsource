//
//  NSString+Testable.h
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Testable)
+(NSString*)filepathFromFileNamed:(NSString*)fileName;
+(NSString*)stringFromFileNamed:(NSString*)fileName;
-(NSArray<NSString*>*)splitIntoEqualParts:(NSInteger)parts;
-(NSArray<NSString*>*)splitIntoPartsApproximatelySized:(NSUInteger)size;
@end
