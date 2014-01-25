//
//  NSMutableArray+Move.h
//  TodoApp
//
//  Created by Ruchi Varshney on 1/25/14.
//  Copyright (c) 2014 Ruchi Varshney. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Move)

- (void)moveObjectFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
