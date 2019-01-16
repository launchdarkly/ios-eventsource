//
//  NSString+Testable.m
//  DarklyEventSourceTests
//
//  Created by Mark Pokorny on 6/29/18. +JMJ
//  Copyright © 2018 Catamorphic Co. All rights reserved.
//

#import "NSString+Testable.h"

@implementation NSString(Testable)
+(NSString*)stringFromFileNamed:(NSString*)fileName {
    NSString *filepath = [NSString filepathFromFileNamed:fileName];
    if (filepath.length == 0) {
        return nil;
    }
    return [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
}

+(NSString*)filepathFromFileNamed:(NSString*)fileName {
    NSString *filepath;
    for (NSBundle *bundle in [NSBundle allBundles]) {
        filepath = [bundle pathForResource:fileName ofType:@"txt"];
        if (filepath) {
            break;
        }
    }
    return filepath;
}

-(NSArray<NSString*>*)splitIntoEqualParts:(NSInteger)parts {
    if (parts < 2) {
        return @[self];
    }
    NSString *remainingString = [self copy];
    NSMutableArray<NSString*> *stringParts = [NSMutableArray arrayWithCapacity:parts];
    NSInteger partLength = [self partLengthForEqualParts:parts];
    while (remainingString.length > 0) {
        NSArray<NSString*>* splitString = [remainingString splitStringAtIndex:partLength];
        [stringParts addObject:splitString.firstObject];
        remainingString = splitString.lastObject;
    }

    return stringParts;
}

-(NSInteger)partLengthForEqualParts:(NSInteger)parts {
    NSInteger partLength = self.length / parts; //Integer division
    partLength += self.length % parts == 0 ? 0 : 1;    //If the parts divide evenly, use the exact amount. If not, take one more.
    return partLength;
}

-(NSArray<NSString*>*)splitIntoPartsApproximatelySized:(NSUInteger)size {
    if (size == 0) {
        return @[self];
    }
    NSString *remainingString = [self copy];
    NSMutableArray<NSString*> *stringParts = [NSMutableArray arrayWithCapacity:self.length / size];
    while (remainingString.length > 0) {
        NSUInteger partLength = size / 2 + arc4random_uniform((uint32_t)size);
        NSArray<NSString*>* splitString = [remainingString splitStringAtIndex:partLength];
        [stringParts addObject:splitString.firstObject];
        remainingString = splitString.lastObject;
    }

    return stringParts;
}

-(NSArray<NSString*>*)splitStringAtIndex:(NSUInteger)index {
    if (index <= self.length) {
        return @[[self substringToIndex:index], [self substringFromIndex:index]];
    }

    return @[self, @""];
}

@end
