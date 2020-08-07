//
//  HanoiTowerScene.h
//  test_HanoiTower
//
//  Created by zhaoxiaojian on 2020/7/27.
//  Copyright © 2020 Zhao Xiaojian. All rights reserved.
//

#import <SceneKit/SceneKit.h>

#define LEFT_POLE_INDEX     0
#define MIDDLE_POLE_INDEX   1
#define RIGHT_POLE_INDEX    2

NS_ASSUME_NONNULL_BEGIN

@interface HanoiTowerScene : SCNScene

-(void)setupSceneInSCNView:(SCNView *)view numDiscs:(NSUInteger)numDiscs;

-(NSInteger)numDiscsOfPole:(NSInteger)poleIndex;

-(BOOL)moveTopDiscFromPoleOfIndex:(NSInteger)fromPoleIndex
                    toPoleOfIndex:(NSInteger)toPoleOfIndex
                         duration:(NSTimeInterval)duration
                       completion:(nullable void(^)(void))block;

@end

NS_ASSUME_NONNULL_END
