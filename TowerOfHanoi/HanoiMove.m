//
//  HanoiMove.m
//  test_HanoiTower
//
//  Created by zhao on 2020/7/27.
//  Copyright © 2020 Zhao Xiaojian. All rights reserved.
//

#import "HanoiMove.h"

@implementation HanoiMove

+ moveFrom:(NSInteger)from to:(NSInteger)to
{
    HanoiMove *move = [[HanoiMove alloc] init];
    move.from = from;
    move.to = to;
    return move;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"move[%@->%@]", @(self.from), @(self.to)];
}

@end
