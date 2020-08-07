//
//  ViewController.m
//  test_HanoiTower
//
//  Created by zhaoxiaojian on 2020/7/27.
//  Copyright © 2020 Zhao Xiaojian. All rights reserved.
//

#import "ViewController.h"
#import <SceneKit/SceneKit.h>
#import "HanoiTowerScene.h"
#import "HanoiMove.h"

const static NSInteger DEFAULT_NUM_DISC = 5;
typedef NS_ENUM(NSInteger, GameState){
    GAME_STATE_INIT,
    GAME_STATE_PAUSED,
    GAME_STATE_PLAYING,
    GAME_STATE_DONE
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet SCNView *scnView;
@property (weak, nonatomic) IBOutlet UILabel *msgLabel;
@property (weak, nonatomic) IBOutlet UISlider *playSpeedSlider;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property GameState gameState; // {0: paused, 1: playing; 2: finished}
@end

@implementation ViewController{
    HanoiTowerScene *_scene;
    NSMutableArray<HanoiMove *> *_hanoiMoves;
    NSTimer *_timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addObserver:self forKeyPath:@"gameState" options:NSKeyValueObservingOptionNew context:NULL];
    self.gameState = GAME_STATE_INIT;
    
    //for debug purpose
    self.scnView.autoenablesDefaultLighting = YES;
    self.scnView.allowsCameraControl = YES;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if(object == self && [keyPath isEqualToString:@"gameState"]){
        NSString *text;
        switch (self.gameState) {
            case GAME_STATE_INIT:
                text = @"";
                break;
            case GAME_STATE_PAUSED:
                text = NSLocalizedString(@"Play", nil);
                break;
            case GAME_STATE_PLAYING:
                text = NSLocalizedString(@"Pause", nil);
                break;
            case GAME_STATE_DONE:
                text = NSLocalizedString(@"Replay", nil);
                break;
        }
        [self.playButton setTitle:text forState:UIControlStateNormal];
    }
}

-(void)_setupNewHanoiGameWithNumDisc:(NSInteger)numDisc
{
    _hanoiMoves = [NSMutableArray array];
    // Build Hanoi moves into _hanoiMoves array
    [self _buildHanoiMoves:numDisc from:LEFT_POLE_INDEX via:MIDDLE_POLE_INDEX to:RIGHT_POLE_INDEX];
    
    NSString *textTotalMoves = NSLocalizedString(@"Total Moves: %@", nil);
    self.msgLabel.text = [NSString stringWithFormat:textTotalMoves, @([_hanoiMoves count])];

    _scene = [[HanoiTowerScene alloc] init];
    self.scnView.scene = _scene;
    [_scene setupSceneInSCNView:self.scnView
                       numDiscs:numDisc];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(self.numDiscs == 0){
        self.numDiscs = DEFAULT_NUM_DISC;
    }
    [self _setupNewHanoiGameWithNumDisc:self.numDiscs];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Start playing hanoi moves
    [self _schedulePlayTimer];
    self.gameState = GAME_STATE_PLAYING;
}

-(void)_schedulePlayTimer
{
    NSTimeInterval timeInterval = [self.playSpeedSlider value];
    _timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval * 0.1
                                     target:self selector:@selector(_timerFired:)
                                   userInfo:NULL repeats:NO];
}

-(void)_timerFired:(NSTimer *)timer
{
    if(self.gameState != GAME_STATE_PLAYING){
        return ;
    }
    if([_hanoiMoves count] == 0){
        self.gameState = GAME_STATE_DONE;
        return ;
    }
    [timer invalidate];
    
    HanoiMove *currentMove = [_hanoiMoves objectAtIndex:0];
    [_hanoiMoves removeObjectAtIndex:0];
    NSString *textMovesLeft = NSLocalizedString(@"Moves Left: %@", nil);
    self.msgLabel.text = [NSString stringWithFormat:textMovesLeft, @([_hanoiMoves count])];
    NSTimeInterval timeInterval = [self.playSpeedSlider value];
    [_scene moveTopDiscFromPoleOfIndex:currentMove.from toPoleOfIndex:currentMove.to duration:timeInterval completion:^{
        // re-schedule timer
        [self _schedulePlayTimer];
    }];
}

// build hanoi moves into array: _hanoiMoves recursively
- (void)_buildHanoiMoves:(NSInteger)n from:(NSInteger)A via:(NSInteger)B to:(NSInteger)C
{
    if(n == 0)
        return ;
    
    if(n == 1){
        // move: A-->C
        [_hanoiMoves addObject:[HanoiMove moveFrom:A to:C]];
        return ;
    }
    
    [self _buildHanoiMoves:n-1 from:A via:C to:B];
    // move: A --> C
    [_hanoiMoves addObject:[HanoiMove moveFrom:A to:C]];
    [self _buildHanoiMoves:n-1 from:B via:A to:C];
}
- (IBAction)pausePlaying:(UIButton *)button
{
    switch(self.gameState){
        case GAME_STATE_INIT:
            break;
        case GAME_STATE_PLAYING:
            [_timer invalidate];
            _timer = nil;
            self.gameState = GAME_STATE_PAUSED;
            break;
        case GAME_STATE_PAUSED:
            [self _schedulePlayTimer];
            self.gameState = GAME_STATE_PLAYING;
            break;
        case GAME_STATE_DONE:
            [self _newGameWithNumDiscs:self.numDiscs];
            break;
    }
}

-(void)_newGameWithNumDiscs:(NSInteger)numDiscs
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    ViewController *viewController = [mainStoryBoard instantiateInitialViewController];
    viewController.numDiscs = numDiscs;
    [self.view.window setRootViewController:viewController];
}

- (IBAction)newHanoiGame:(UIButton *)sender
{
    NSString *textNewGamePrompt = NSLocalizedString(@"Input number of discs between 1 and 20", nil);
    NSString *textCancel = NSLocalizedString(@"Cancel", nil);
    NSString *textNewGame = NSLocalizedString(@"New Game", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:textNewGamePrompt preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       textField.text = [NSNumberFormatter localizedStringFromNumber:@(DEFAULT_NUM_DISC) numberStyle:0];
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:textCancel style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:textNewGame style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSInteger numDiscs = [[alertController.textFields firstObject].text integerValue];
        if(numDiscs >= 1 && numDiscs <= 20){
            [self _newGameWithNumDiscs:numDiscs];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
