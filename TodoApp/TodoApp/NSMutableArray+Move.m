//
//  NSMutableArray+Move.m
//  TodoApp
//
//  Created by Ruchi Varshney on 1/25/14.
//  Copyright (c) 2014 Ruchi Varshney. All rights reserved.
//

#import "NSMutableArray+Move.h"

@implementation NSMutableArray (Move)

- (void)moveObjectFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    if (toIndex != fromIndex) {
        id object = [self objectAtIndex:fromIndex];
        [self removeObjectAtIndex:fromIndex];
        [self insertObject:object atIndex:toIndex];
    }
}

@end
