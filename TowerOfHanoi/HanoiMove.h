//
//  HanoiMove.h
//  test_HanoiTower
//
//  Created by zhao on 2020/7/27.
//  Copyright © 2020 Zhao Xiaojian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HanoiMove : NSObject

@property NSInteger from;
@property NSInteger to;

+ moveFrom:(NSInteger)from to:(NSInteger)to;

@end

NS_ASSUME_NONNULL_END
