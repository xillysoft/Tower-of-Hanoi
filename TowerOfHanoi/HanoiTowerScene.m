//
//  HanoiTowerScene.m
//  test_HanoiTower
//
//  Created by zhaoxiaojian on 2020/7/27.
//  Copyright © 2020 Zhao Xiaojian. All rights reserved.
//

#import "HanoiTowerScene.h"

#define RADIANS(degrees) ((degrees) * M_PI / 180.0)
#define DEGREES(radians) ((radians) * 180.0 / M_PI)
const static CGFloat POLE_RADIUS = 0.1;

const static CGFloat DISC_HEIGHT = 0.3;
const static CGFloat DISC_RADIUS_MIN = 0.4; //MUST: >polekRadius
const static CGFloat DISC_RADIUS_MAX = 1.5;

const static CGFloat DISC_PADDING = 0.1;
const static CGFloat BOARD_PADDING = 0.5;




@implementation HanoiTowerScene{
    CGFloat _poleXPositions[3]; //0: left pole; 1: middle pole; 2: right pole
    CGFloat _poleBottomY;
    CGFloat _polekHeight;
    SCNNode *_poleNodes[3];
    SCNNode *_cameraNode;
    
    NSArray<NSMutableArray<SCNNode *> *> *_discNodes;
}


-(void)setupSceneInSCNView:(SCNView *)view numDiscs:(NSUInteger)numDiscs
{
    self.background.contents = [UIColor whiteColor];
    SCNNode *rootNode = [self rootNode];
    
    // Add floor in the scene
    SCNNode *floorNode = [SCNNode nodeWithGeometry:[SCNFloor floor]];
    floorNode.position = SCNVector3Make(0, 0, -0.01);
    floorNode.geometry.firstMaterial.diffuse.contents = [UIColor whiteColor];
//    floorNode.categoryBitMask = 0x0;
//    floorNode.opacity = 0.5;
    [rootNode addChildNode:floorNode];
    
    const CGFloat poleDistance = DISC_RADIUS_MAX * 2 + DISC_PADDING; //MUST: >= discRadiusMax*2;

    const CGFloat poleMarginHeight = 1.0;
    _polekHeight = numDiscs * DISC_HEIGHT + poleMarginHeight;
    _poleXPositions[LEFT_POLE_INDEX] = -poleDistance;
    _poleXPositions[MIDDLE_POLE_INDEX] = 0.0;
    _poleXPositions[RIGHT_POLE_INDEX] = +poleDistance;
    _poleBottomY = 0.0;
    
    SCNNode *leftPole = [SCNNode nodeWithGeometry:[SCNCylinder cylinderWithRadius:POLE_RADIUS height:_polekHeight]];
    leftPole.pivot = SCNMatrix4MakeTranslation(0, -_polekHeight/2, 0); //set origin point of SCNCylinder to bottom
    leftPole.position = SCNVector3Make(_poleXPositions[LEFT_POLE_INDEX], _poleBottomY, 0);
    leftPole.geometry.firstMaterial.diffuse.contents = [UIColor redColor];
    leftPole.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
    leftPole.geometry.firstMaterial.specular.contents = [UIColor whiteColor];
    leftPole.geometry.firstMaterial.shininess = 8.0;
    [rootNode addChildNode:leftPole];
    _poleNodes[LEFT_POLE_INDEX] = leftPole;
    
    SCNNode *middlePole = [leftPole clone];
    middlePole.pivot = SCNMatrix4MakeTranslation(0, -_polekHeight/2, 0); //set origin point of SCNCylinder to bottom
    middlePole.position = SCNVector3Make(_poleXPositions[MIDDLE_POLE_INDEX], _poleBottomY, 0);
    middlePole.geometry = [leftPole.geometry copy];
    middlePole.geometry.materials = ({
        SCNMaterial *m = [SCNMaterial material];
        m.diffuse.contents = [UIColor blueColor];
        @[m];
    });
    [rootNode addChildNode:middlePole];
    _poleNodes[MIDDLE_POLE_INDEX] = middlePole;
    
    SCNNode *rightPole = [leftPole clone];
    rightPole.pivot = SCNMatrix4MakeTranslation(0, -_polekHeight/2, 0); //set origin point of SCNCylinder to bottom
    rightPole.position = SCNVector3Make(_poleXPositions[RIGHT_POLE_INDEX], _poleBottomY, 0);
    rightPole.geometry = [leftPole.geometry copy];
    rightPole.geometry.materials = ({
        SCNMaterial *m = [SCNMaterial material];
        m.diffuse.contents = [UIColor greenColor];
        @[m];
    });
    [rootNode addChildNode:rightPole];
    _poleNodes[RIGHT_POLE_INDEX] = rightPole;
    
    [self _createDiscNodes:numDiscs];
        
    //Add Lights
    SCNNode *lightNodeAmbinet = [SCNNode node];
    lightNodeAmbinet.light = [SCNLight light];
    lightNodeAmbinet.light.type = SCNLightTypeAmbient;
    lightNodeAmbinet.light.color = [UIColor darkGrayColor];
    [rootNode addChildNode:lightNodeAmbinet];
    
    SCNNode *lightNodeOmni = [SCNNode node];
    lightNodeOmni.light = [SCNLight light];
    lightNodeOmni.light.type = SCNLightTypeOmni;
    lightNodeOmni.light.color = [UIColor grayColor];
    lightNodeOmni.position = SCNVector3Make(0, 0, 10.0);
    [rootNode addChildNode:lightNodeOmni];

    SCNNode *lightNodeSpot = [SCNNode node];
    lightNodeSpot.light = [SCNLight light];
    lightNodeSpot.light.type = SCNLightTypeSpot;
    lightNodeSpot.light.color = [UIColor whiteColor];
    lightNodeSpot.light.spotInnerAngle = 60.0;
    lightNodeSpot.light.spotOuterAngle = 120.0;
    lightNodeSpot.light.castsShadow = YES;
    lightNodeSpot.light.shadowRadius = 15.0;
    lightNodeSpot.light.shadowSampleCount = 128;
    lightNodeSpot.position = SCNVector3Make(-5, 10, 10);
    lightNodeSpot.eulerAngles = SCNVector3Make(RADIANS(-20.0), RADIANS(-10.0), 0);
    [rootNode addChildNode:lightNodeSpot];
    
    // Setting Camera
    _cameraNode = [SCNNode node];
    _cameraNode.camera = [SCNCamera camera];
    _cameraNode.camera.orthographicScale = NO; //perspective projection
    const CGFloat xFov = 60.0;
    const CGFloat ratio = view.bounds.size.height / view.bounds.size.width;
    const CGFloat yFov = 2 * DEGREES(atan(tan(RADIANS(xFov * 0.5)) * ratio));;
    _cameraNode.camera.xFov = xFov;
    _cameraNode.camera.yFov = yFov;
    NSLog(@"yFov = %.2f", _cameraNode.camera.yFov);
    //adjust camera distance to make sure all node shown
    const CGFloat boardWidth = poleDistance*2 + DISC_RADIUS_MAX*2 + BOARD_PADDING*2 + 0.1; // ≥ 2*DISC_RADIUS_MAX + DISC_RADIUS_MAX
//    const CGFloat boardLength = DISC_RADIUS_MAX*2 + BOARD_PADDING*2;
    const CGFloat boardHeight = _polekHeight + 0.1;

    CGFloat minCameraZ = MAX(MAX(boardWidth*0.5 / tan(RADIANS(xFov * 0.5)),
                             boardHeight / tan(RADIANS(yFov * 0.5))), //make sure all scene nodes in camera
                             boardWidth*0.5); //in case when scene rotate 90 around y- axis
    NSLog(@"minCameraZ=%.2f", minCameraZ);
    
    const CGFloat cameraY = _polekHeight;
    _cameraNode.position = SCNVector3Make(0, cameraY, minCameraZ);
    _cameraNode.eulerAngles = SCNVector3Make(RADIANS(-10), 0, 0);
    [rootNode addChildNode:_cameraNode];

    // Point of View
    [view setPointOfView:_cameraNode];
}

// Add disc nodes to the scene
-(void)_createDiscNodes:(NSUInteger)numDiscs
{
    SCNNode *rootNode = [self rootNode];

    //0: left discs, 1:middle dics, 2:rightdiscs
    _discNodes = @[[NSMutableArray array], [NSMutableArray array], [NSMutableArray array]];
    
    for(NSUInteger i=0; i<numDiscs; i++){
        CGFloat diskInnerRadius = POLE_RADIUS;
        //disc radius: [i=0]:discRadiusMax -> [i=N-1]:discRadiusMin
        CGFloat diskRadius = numDiscs==1 ? DISC_RADIUS_MAX : i * (DISC_RADIUS_MIN - DISC_RADIUS_MAX)/ (numDiscs - 1) + DISC_RADIUS_MAX;
        SCNNode *discNode = [SCNNode nodeWithGeometry:[SCNTube tubeWithInnerRadius:diskInnerRadius
                                                                       outerRadius:diskRadius
                                                                            height:DISC_HEIGHT]];
        CGFloat discNodeX = _poleXPositions[LEFT_POLE_INDEX];
        CGFloat discNodeY = DISC_HEIGHT*0.5 + i*DISC_HEIGHT; //origin point of SCNTube is at the center
        discNode.position = SCNVector3Make(discNodeX, discNodeY, 0);

        const CGFloat hueMin = 0.05;
        const CGFloat huiMax = 0.95;
        CGFloat hue = numDiscs == 1 ? hueMin : i * (huiMax - hueMin) / (numDiscs - 1) + hueMin;
        discNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
        discNode.geometry.firstMaterial.locksAmbientWithDiffuse = YES;
        discNode.geometry.firstMaterial.specular.contents = [UIColor whiteColor];
        discNode.geometry.firstMaterial.shininess = 32;
        [rootNode addChildNode:discNode];
        
        //Initially, all discs place in Left Pole
        [[_discNodes objectAtIndex:LEFT_POLE_INDEX] addObject:discNode];
    }
}

-(NSInteger)numDiscsOfPole:(NSInteger)poleIndex
{
    return [_discNodes[poleIndex] count];
}

-(BOOL)moveTopDiscFromPoleOfIndex:(NSInteger)fromPoleIndex toPoleOfIndex:(NSInteger)toPoleOfIndex duration:(NSTimeInterval)duration completion:(nullable void(^)(void))completion
{
//    NSLog(@"moveTopDiscFromPoleOfIndex:toPoleOfIndex:! [_discNodes[fromPoleIndex] count]=%@", @([_discNodes[fromPoleIndex] count]));
    if([_discNodes[fromPoleIndex] count] == 0){ //No disc within pole: fromPoleIndex
        return NO;
    }
    
    //top-most disc
    SCNNode *discNode = [_discNodes[fromPoleIndex] lastObject];
    [_discNodes[fromPoleIndex] removeLastObject];
    [_discNodes[toPoleOfIndex] addObject:discNode];

    SCNVector3 pos0 = discNode.position;
    NSInteger numDiscsInToPole = [_discNodes[toPoleOfIndex] count];
    CGFloat discNodeDestY = DISC_HEIGHT*0.5 + (numDiscsInToPole - 1) * DISC_HEIGHT; //origin point of SCNTube is at the center
    CGFloat discNodeDestX = _poleXPositions[toPoleOfIndex];
    
    SCNVector3 pos1 = SCNVector3Make(discNodeDestX, discNodeDestY, pos0.z);
    //    discNode.position = destPosition;
    const CGFloat liftingY = _polekHeight + DISC_HEIGHT/2;
    SCNAction *moveAction1 = [SCNAction moveTo:SCNVector3Make(pos0.x, liftingY, pos0.z) duration:duration*0.3]; //lift up
    SCNAction *moveAction2 = [SCNAction moveTo:SCNVector3Make(pos1.x, liftingY, pos0.z) duration:duration*0.4]; //move
    SCNAction *moveAction3 = [SCNAction moveTo:SCNVector3Make(pos1.x, pos1.y, pos0.z) duration:duration*0.3]; //put down
    [discNode runAction:[SCNAction sequence:@[moveAction1, moveAction2, moveAction3]]
                          completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), completion);
    }];

    return YES;
}

@end
