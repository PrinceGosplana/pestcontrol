#import "MyScene.h"
#import "TileMapLayer.h"
#import "TileMapLayerLoader.h"
#import "Player.h"
#import "Bug.h"
#import "Breakable.h"
#import "FireBug.h"
#import "TmxTileMapLayer.h"
#import "SKNode+SKTExtras.h"
#import "SKAction+SKTExtras.h"
#import "SKTEffects.h"
#import "SKEmitterNode+SKTExtras.h"
#import "SKTAudio.h"

static SKAction * HitWallSound;
static SKAction * HitWaterSound;
static SKAction * HitTreeSound;
static SKAction * HitFireBugSound;
static SKAction * PlayerMoveSound;
static SKAction * TickTockSound;
static SKAction * WinSound;
static SKAction * LoseSound;
static SKAction * KillBugSounds[12];

@interface MyScene () <SKPhysicsContactDelegate>
@end

@implementation MyScene {
    SKNode * _worldNode;
    TileMapLayer * _bgLayer;
    
    Player * _player;
    
    TileMapLayer * _bugLayer;
    TileMapLayer * _breakableLayer;
    
    JSTileMap * _tileMap;
    
    PCGameState _gameState;
    
    int _level;
    
    double _levelTimeLimit;
    SKLabelNode* _timerLabel;
    
    double _currentTime;
    double _startTime;
    double _elapsedTime;
    
    CFTimeInterval _lastComboTime;
    int _comboCounter;
    
    BOOL _tickTockPlaying;
}

+ (void)initialize
{
    if ([self class] == [MyScene class]) {
        
        HitWallSound = [SKAction playSoundFileNamed:@"HitWall.mp3"  waitForCompletion:NO];
        HitWaterSound = [SKAction playSoundFileNamed:@"HitWater.mp3" waitForCompletion:NO];
        HitTreeSound = [SKAction playSoundFileNamed:@"HitTree.mp3" waitForCompletion:NO];
        HitFireBugSound = [SKAction playSoundFileNamed:@"HitFireBug.mp3" waitForCompletion:NO];
        PlayerMoveSound = [SKAction playSoundFileNamed:@"PlayerMove.mp3" waitForCompletion:NO];
        TickTockSound = [SKAction playSoundFileNamed:@"TickTock.mp3" waitForCompletion:YES];
        WinSound = [SKAction playSoundFileNamed:@"Win.mp3" waitForCompletion:NO];
        LoseSound = [SKAction playSoundFileNamed:@"Lose.mp3" waitForCompletion:NO];
        
        for (int t = 0; t < 12; ++t) {
            KillBugSounds[t] =
            [SKAction playSoundFileNamed: [NSString stringWithFormat:@"KillBug-%d.mp3", t+1] waitForCompletion:NO];
        }
    }
}


-(id)initWithSize:(CGSize)size level:(int)level{
    if (self = [super initWithSize:size]) {
        NSDictionary * config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"myLevels" ofType:@"plist"]];
        if (level < 0 || level >= [config[@"mylevels"] count]) {
            level = 0;
        }
        _level = level;
        NSDictionary * levelData = config[@"mylevels"][level];
        if (levelData[@"tmxFile"]) {
            _tileMap = [JSTileMap mapNamed:levelData[@"tmxFile"]];
        }
        _levelTimeLimit = [levelData[@"timeLimit"] doubleValue];
        
        [self createWorld:levelData];
        [self createCharacters:levelData];
        [self centerViewOn:_player.position];
        [self createUserInterface];
        _gameState = PCGameStateStartingLevel;
        
        self.backgroundColor = SKColorWithRGB(89, 133, 39);
        
        [[SKTAudio sharedInstance] playBackgroundMusic:@"Music.mp3"];
        
    }
    return self;
}

#pragma mark -
#pragma mark Centered World

- (void)centerViewOn:(CGPoint)centerOn {
//    CGSize size = self.size;
//    CGFloat x = Clamp(centerOn.x, size.width / 2, _bgLayer.layerSize.width - size.width / 2);
//    CGFloat y = Clamp(centerOn.y, size.height / 2, _bgLayer.layerSize.height - size.height/ 2);
//    _worldNode.position = CGPointMake(-x, -y);
    
    _worldNode.position = [self pointToCenterViewOn:centerOn];
}

- (CGPoint) pointToCenterViewOn: (CGPoint) centerOn {
    CGSize size = self.size;
    
    CGFloat x = Clamp(centerOn.x, size.width / 2,
                      _bgLayer.layerSize.width - size.width / 2);
    
    CGFloat y = Clamp(centerOn.y, size.height / 2,
                      _bgLayer.layerSize.height - size.height / 2);
    
    return CGPointMake(-x, -y);
}


- (void) didSimulatePhysics {
    CGPoint target = [self pointToCenterViewOn:_player.position];
    
    CGPoint newPosition = _worldNode.position;
    newPosition.x += (target.x - _worldNode.position.x) * 0.1f;
    newPosition.y += (target.y - _worldNode.position.y) * 0.1f;
    
    _worldNode.position = newPosition;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    switch (_gameState) {
        case PCGameStateStartingLevel:
        {
            self.paused = NO;
            [self childNodeWithName:@"msgLabel"].hidden = YES;
            _gameState = PCGameStatePlaying;
            // intentionally omitted break
            _timerLabel.hidden = NO;
            _startTime = _currentTime;
            [_player start];
        }
        case PCGameStatePlaying: {
             UITouch * touch = [touches anyObject];
            [self tapEffectsForTouch:touch];
            [_player moveToward:[touch locationInNode:_worldNode]];
            
        }
            break;
        case PCGameStateInLevelMenu: {
            UITouch * touch = [touches anyObject];
            CGPoint loc = [touch locationInNode:self];
            
            SKNode * node = [self childNodeWithName:@"nextLevelLabel"];
            if ([node containsPoint:loc]) {
                MyScene * newScene = [[MyScene alloc] initWithSize:self.size level:_level + 1];
                newScene.userData = self.userData;//TODO:del
                [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
                
            } else {
                node = [self childNodeWithName:@"retryLabel"];
                if ([node containsPoint:loc]) {
                    MyScene * newScene = [[MyScene alloc] initWithSize:self.size level:_level];
                    newScene.userData = self.userData;//TODO:del
                    [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
                }
            }
            break;
        }
        case PCGameStateInReloadMenu: {
            UITouch * touch = [touches anyObject];
            CGPoint loc = [touch locationInNode:self];
            SKNode * node = [self nodeAtPoint:loc];
            if ([node.name isEqualToString:@"restartLabel"]) {
                MyScene * newScene = [[MyScene alloc] initWithSize:self.size level:_level];
                newScene.userData = self.userData;//TODO:del
                [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:.5]];
            } else if ([node.name isEqualToString:@"continueLabel"]) {
                _startTime = _currentTime - _elapsedTime;
                [node removeFromParent];
                node = [self childNodeWithName:@"restartLabel"];
                [node removeFromParent];
                [self childNodeWithName:@"msgLabel"].hidden = YES;
                
                _gameState = PCGameStatePlaying;
                self.paused = NO;
            }
            break;
        }
        default:
            break;
    }
    
}

- (TileMapLayer *)createScenery:(NSDictionary *)levelData {
    //    _tileMap = [JSTileMap mapNamed:@"level-3-sapmle.tmx"];
    //    return [[TmxTileMapLayer alloc] initWithTmxLayer:[_tileMap layerNamed:@"Background"]];
//    return [TileMapLayerLoader tileMapLayerFromFileNamed:@"myLevel-2-bg.txt"];
    if (_tileMap) {
        return [[TmxTileMapLayer alloc] initWithTmxLayer:[_tileMap layerNamed:@"Background"]];
    } else {
        NSDictionary * layerFiles = levelData[@"layers"];
        return [TileMapLayerLoader tileMapLayerFromFileNamed:layerFiles[@"background"]];
    }
}

- (void) createWorld: (NSDictionary *) levelData {
    _bgLayer = [self createScenery:levelData];

    _worldNode = [SKNode node];
    if (_tileMap) {
        [_worldNode addChild:_tileMap];
    }
    [_worldNode addChild:_bgLayer];
    [self addChild:_worldNode];
    
    self.anchorPoint = CGPointMake(0.5, 0.5);
    _worldNode.position = CGPointMake(- _bgLayer.layerSize.width / 2, - _bgLayer.layerSize.height / 2);
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);

    // create boundary
    SKNode * bounds = [SKNode node];
    bounds.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, _bgLayer.layerSize.width, _bgLayer.layerSize.height)];
    bounds.physicsBody.categoryBitMask = PCPhysicsCategoryBoundary;
    bounds.physicsBody.friction = 0;
    bounds.name = @"worldBounds";
    [_worldNode addChild:bounds];
    
    self.physicsWorld.contactDelegate = self;
    
    _breakableLayer = [self createBreakables:levelData];
    if (_breakableLayer) {
        [_worldNode addChild:_breakableLayer];
    }
}

#pragma mark -
#pragma mark Did contact

- (void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody * other = (contact.bodyA.categoryBitMask == PCPhysicsCategoryPlayer ? contact.bodyB : contact.bodyA);

    if (other.categoryBitMask == PCPhysicsCategoryBug) {
//        [other.node removeFromParent];
        [self bugHitEffects:(SKSpriteNode *)other.node];
    } else if (other.categoryBitMask & PCPhysicsCategoryBreakable) {
        Breakable * breakable = (Breakable *)other.node;
        [breakable smashBreakable];
    }
    else if (other.categoryBitMask & PCPhysicsCategoryFireBug) {
        [self fireBugHitEffects];
        FireBug *fireBug = (FireBug *)other.node;
        [fireBug kickBug];
    } else if (other.categoryBitMask & (PCPhysicsCategoryBoundary | PCPhysicsCategoryWall | PCPhysicsCategoryWater | PCPhysicsCategoryCrackedWall)) {
        [self wallHitEffects:other.node];
    }
}

- (BOOL)tileAtCoord:(CGPoint)coord hasAnyProps:(uint32_t)props {
    return [self tileAtPoint:[_bugLayer pointForcoord:coord] hasAnyProps:props];
}

- (BOOL)tileAtPoint:(CGPoint)point hasAnyProps:(uint32_t)props {
    SKNode * tile = [_breakableLayer tileAtPoint:point];
    if (!tile) {
        tile = [_bgLayer tileAtPoint:point];
    }
    return tile.physicsBody.categoryBitMask & props;
}

- (void) didEndContact:(SKPhysicsContact *)contact {
    SKPhysicsBody * other = (contact.bodyA.categoryBitMask == PCPhysicsCategoryPlayer ? contact.bodyB : contact.bodyA);
    
    if (other.categoryBitMask & _player.physicsBody.collisionBitMask) {
        [_player faceCurrentDirection];
    }
}

- (Side) sideForCollisionWithNode: (SKNode *)node {
    if (node.physicsBody.collisionBitMask & PCPhysicsCategoryBoundary) {
        if (_player.position.x < 20.0f) {
            return SideLeft;
        } else if (_player.position.y < 20.0f) {
            return SideBottom;
        } else if (_player.position.x > self.size.width - 20.0f) {
            return SideRight;
        } else {
            return SideTop;
        }
    } else {
        CGPoint diff = CGPointSubtract(node.position, _player.position);
        CGFloat angle = CGPointToAngle(diff);
        
        if (angle > - M_PI_4 && angle <= M_PI_4) {
            return SideRight;
        } else if (angle > M_PI_4 && angle <= 3.0f * M_PI_4) {
            return SideTop;
        } else if (angle <= - M_PI_4 && angle > -3.0f * M_PI_4) {
            return SideBottom;
        } else {
            return SideLeft;
        }
    }
}
#pragma mark -
#pragma mark Create persons

- (void) createCharacters:(NSDictionary *)levelData {
    NSDictionary * layersFiles = levelData[@"layers"];

    _bugLayer = [TileMapLayerLoader tileMapLayerFromFileNamed:layersFiles[@"bugs"]];
    [_worldNode addChild:_bugLayer];
    
    _player = [Player node];
    _player.position = CGPointMake(400, 400);
    [_worldNode addChild:_player];
    
    //TODO: block bugs moved
    [_bugLayer enumerateChildNodesWithName:@"bug" usingBlock:^(SKNode *node, BOOL *stop) {
        [(Bug *)node start];
    }];
}

- (TileMapLayer *) createBreakables: (NSDictionary *) levelData {
    NSDictionary * layerFiles = levelData[@"layers"];
    return [TileMapLayerLoader tileMapLayerFromFileNamed: layerFiles[@"breakables"]];
}

#pragma mark -
#pragma mark Game state

// adds a label to the scene instructing the user to tap the screen to begin running
- (void)createUserInterface {
    SKLabelNode* startMsg = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    startMsg.name = @"msgLabel";
    startMsg.text = @"Tap Screen to run!";
    startMsg.fontSize = 32;
    startMsg.position = CGPointMake(0, 20);
    [self addChild: startMsg];
    
    _timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _timerLabel.text = [NSString stringWithFormat:@"Time Remaining: %2.2f", _levelTimeLimit];
    _timerLabel.fontSize = 18;
    _timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _timerLabel.position = CGPointMake(self.size.height / 4, self.size.width / 2 - 50);
    [self addChild:_timerLabel];
    _timerLabel.hidden = YES;
}

//- (void) didMoveToView:(SKView *)view {
//    if (PCGameStateStartingLevel == _gameState) {
//        self.paused = YES;
//    }
//}

- (void)update:(NSTimeInterval)currentTime {
    _currentTime = currentTime;
    if ((PCGameStateStartingLevel == _gameState || PCGameStateInReloadMenu == _gameState) && !self.isPaused) {
        self.paused = YES;
    }
    if (_gameState != PCGameStatePlaying) {
        return;
    }
    _elapsedTime = currentTime - _startTime;
    CFTimeInterval timeRemaning = _levelTimeLimit - _elapsedTime;
    if (timeRemaning < 0) {
        timeRemaning = 0;
    }
    _timerLabel.text = [NSString stringWithFormat:@"Time Remaning: %2.2f", timeRemaning];
    if (_elapsedTime >= _levelTimeLimit) {
        [self endLevelWithSuccess:NO];
    } else if (![_bugLayer childNodeWithName:@"bug"]) {
        [self endLevelWithSuccess:YES];
    }
    
    if (timeRemaning < 10 && timeRemaning > 0 && !_tickTockPlaying) {
        _tickTockPlaying = YES;
        [self runAction:TickTockSound withKey:@"tickTock"];
    }
}

- (void) endLevelWithSuccess: (BOOL) won {
    [self removeActionForKey:@"tickTock"];
    SKLabelNode * label = (SKLabelNode *)[self childNodeWithName:@"msgLabel"];
    label.text = (won ? @"You Winn!!!" : @"Too Slow!!!");
    label.hidden = NO;
    //2
    SKLabelNode* nextLevel =
    [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    nextLevel.text = @"Next Level?";
    nextLevel.name = @"nextLevelLabel";
    nextLevel.fontSize = 28;
    nextLevel.horizontalAlignmentMode = (won ? SKLabelHorizontalAlignmentModeCenter : SKLabelHorizontalAlignmentModeLeft);
    nextLevel.position = (won ? CGPointMake(0, -40) : CGPointMake(0+20, -40));
    [self addChild:nextLevel];
    //3
    _player.physicsBody.linearDamping = 1;
    
    _gameState = PCGameStateInLevelMenu;
    
    if (!won) {
        SKLabelNode * tryAgain = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        tryAgain.text = @"Try Again?";
        tryAgain.name = @"retryLabel";
        tryAgain.fontSize = 28;
        tryAgain.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        tryAgain.position = CGPointMake(-20, -40);
        [self addChild:tryAgain];
    }
    
    if (won) {
        NSMutableDictionary *records = self.userData[@"bestTimes"];
        CGFloat bestTime = [records[@(_level)] floatValue];
        if( !bestTime || _elapsedTime < bestTime) {
            records[@(_level)] = @(_elapsedTime);
            label.text = [NSString stringWithFormat: @"New Record! %2.2f", _elapsedTime];
        }
    }
    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:won ? WinSound : LoseSound];
}

- (void) showReloadMenu {
    SKLabelNode* label = (SKLabelNode*)[self childNodeWithName:@"msgLabel"];
    label.text = @"Found a Save File";
    label.hidden = NO;
    SKLabelNode* continueLabel = (SKLabelNode*) [self childNodeWithName:@"continueLabel"];
    
    if (!continueLabel) {
        continueLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        continueLabel.text = @"Continue?";
        continueLabel.name = @"continueLabel";
        continueLabel.fontSize = 28;
        continueLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        continueLabel.position = CGPointMake(-20, -40);
        [self addChild:continueLabel];
        
        SKLabelNode * restartLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        restartLabel.text = @"Restart Level?";
        restartLabel.name = @"restartLabel";
        restartLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        restartLabel.position = CGPointMake(20, -40);
        [self addChild:restartLabel];
    }
}

#pragma mark Saving and loading state

- (void)encodeWithCoder:(NSCoder *)aCoder {
    SKNode * worldBounds = [_worldNode childNodeWithName:@"worldBounds"];
    [worldBounds removeFromParent];
    
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_worldNode forKey:@"MyScene-WorldNode"];
    [aCoder encodeObject:_player forKey:@"MyScene-Player"];
    [aCoder encodeObject:_bgLayer forKey:@"MyScene-BgLayer"];
    [aCoder encodeObject:_bugLayer forKey:@"MyScene-BugLayer"];
    [aCoder encodeObject:_breakableLayer forKey:@"MyScene-BreakableLayer"];
    [aCoder encodeObject:_tileMap forKey:@"MyScene-TmxTileMap"];
    [aCoder encodeInt32:_gameState forKey:@"MyScene-GameState"];
    [aCoder encodeInt:_level forKey:@"MyScene-Level"];
    [aCoder encodeDouble:_levelTimeLimit forKey:@"MyScene-LevelTimeLimit"];
    [aCoder encodeObject:_timerLabel forKey:@"MyScene-TimerLabel"];
    //2
    [aCoder encodeDouble:_elapsedTime forKey:@"MyScene-ElapsedTime"];
    [_worldNode addChild:worldBounds];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _worldNode = [aDecoder decodeObjectForKey:@"MyScene-WorldNode"];
        _player = [aDecoder decodeObjectForKey:@"MyScene-Player"];
        _bgLayer = [aDecoder decodeObjectForKey:@"MyScene-BgLayer"];
        _bugLayer = [aDecoder decodeObjectForKey:@"MyScene-BugLayer"];
        _breakableLayer = [aDecoder decodeObjectForKey:@"MyScene-BreakableLayer"];
        _tileMap = [aDecoder decodeObjectForKey:@"MyScene-TmxTileMap"];
        _gameState = [aDecoder decodeInt32ForKey:@"MyScene-GameState"];
        _level = [aDecoder decodeIntForKey:@"MyScene-Level"];
        _levelTimeLimit = [aDecoder decodeDoubleForKey:@"MyScene-LevelTimeLimit"];
        _timerLabel = [aDecoder decodeObjectForKey:@"MyScene-TimerLabel"];
        _elapsedTime = [aDecoder decodeDoubleForKey:@"MyScene-ElapsedTime"];
        [self removeActionForKey:@"tickTock"];
        
        SKNode * bounds = [SKNode node];
        bounds.name = @"worldBounds";
        bounds.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, _bgLayer.layerSize.width, _bgLayer.layerSize.height)];
        bounds.physicsBody.categoryBitMask = PCPhysicsCategoryBoundary;
        bounds.physicsBody.collisionBitMask = 0;
        bounds.physicsBody.friction = 0;
        [_worldNode addChild:bounds];
        
        switch (_gameState) {
            case PCGameStateInReloadMenu:
            case PCGameStatePlaying:
            {
                _gameState = PCGameStateInReloadMenu;
                [self showReloadMenu];
            }
                break;
                
            default:
                break;
        }
    }
    return self;
}

#pragma mark Effect

- (void) scaleWall: (SKNode *) node {
    
    if ([node actionForKey:@"scaling"] == nil) {
        CGPoint oldScale = CGPointMake(node.xScale, node.yScale);
        CGPoint newScale = CGPointMultiplyScalar(oldScale, 1.2f);
        
        SKTScaleEffect * scaleEffect = [SKTScaleEffect effectWithNode:node duration:1.2 startScale:newScale endScale:oldScale];
        
        scaleEffect.timingFunction = SKTCreateShakeFunction(4);
        SKAction * action = [SKAction actionWithEffect:scaleEffect];
        
        [node runAction:action withKey:@"scaling"];
    }
}

- (void) wallHitEffects: (SKNode *) node {
    Side side = [self sideForCollisionWithNode:node];
    [self squashPlayerForSide:side];
    if (node.physicsBody.categoryBitMask & PCPhysicsCategoryBoundary) {
        [self screenShakeForSide:side power:20.0f];
        [self bugJelly];
    } else {
        [node skt_bringToFront];
        [self scaleWall:node];
        [self moveWall:node onSide:side];
        [self crackWall:(SKSpriteNode *)node];
        [self screenShakeForSide:side power:8.0f];
        [self showParticlesForWall:node onSide:side];
    }
    if (node.physicsBody.categoryBitMask & PCPhysicsCategoryWater) {
        [self runAction:HitWaterSound];
    } else {
        [self runAction:HitWallSound];
    }
}

- (void) moveWall: (SKNode *) node onSide: (Side) side {
    if ([node actionForKey:@"moving"] == nil) {
        static CGPoint offsets[] = {
            { 4.0f, 0.0f },
            { 0.0f, 4.0f },
            { -4.0f, 0.0f },
            { 0.0f, -4.0f }
        };
        
        CGPoint oldPosition = node.position;
        CGPoint offset = offsets[side];
        CGPoint newPosition = CGPointAdd(node.position, offset);
        
        SKTMoveEffect * moveEffect = [SKTMoveEffect effectWithNode:node duration:0.6 startPosition:newPosition endPosition:oldPosition];
        
        moveEffect.timingFunction = SKTTimingFunctionBackEaseOut;
        
        SKAction * action = [SKAction actionWithEffect:moveEffect];
        [node runAction:action withKey:@"moving"];
    }
}

- (void) tapEffectsForTouch: (UITouch *) touch {
    [self stretchPlayerWhenMoved];
    [self showTapAtLocation:[touch locationInNode:_worldNode]];
    [_player runAction:PlayerMoveSound];
}

- (void) stretchPlayerWhenMoved {
    CGPoint oldScale = CGPointMake(_player.xScale, _player.yScale);
    CGPoint newScale = CGPointMultiplyScalar(oldScale, 1.4f);
    
    SKTScaleEffect * scaleEffect = [SKTScaleEffect effectWithNode:_player duration:0.2 startScale:newScale endScale:oldScale];
    scaleEffect.timingFunction = SKTTimingFunctionSmoothstep;
    [_player runAction:[SKAction actionWithEffect:scaleEffect]];
}

- (void) squashPlayerForSide: (Side) side {
    if ([_player actionForKey:@"squash"] != nil) {
        return;
    }
    
    CGPoint oldScale = CGPointMake(_player.xScale, _player.yScale);
    CGPoint newScale = oldScale;
    
    const float ScaleFactor = 1.6f;
    
    if (side == SideTop || side == SideBottom) {
        newScale.x *= ScaleFactor;
        newScale.y /= ScaleFactor;
    } else {
        newScale.x /= ScaleFactor;
        newScale.y *= ScaleFactor;
    }
    
    SKTScaleEffect * scaleEffect = [SKTScaleEffect effectWithNode:_player duration:0.2 startScale:newScale endScale:oldScale];
    scaleEffect.timingFunction = SKTTimingFunctionQuinticEaseOut;
    [_player runAction:[SKAction actionWithEffect:scaleEffect] withKey:@"squash"];
}

- (void) bugJelly {
    [_bugLayer enumerateChildNodesWithName:@"bug" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node actionForKey:@"scaling"] == nil) {
            CGPoint oldScale = CGPointMake(node.xScale, node.yScale);
            CGPoint newScale = CGPointMultiplyScalar(oldScale, 1.2f);

            SKTScaleEffect * scaleEffect = [SKTScaleEffect effectWithNode:node duration:1.2 startScale:newScale endScale:oldScale];
            scaleEffect.timingFunction = SKTTimingFunctionElasticEaseOut;
            
            SKAction * action = [SKAction actionWithEffect:scaleEffect];
            [node runAction:action withKey:@"scaling"];
        }
    }];
}

- (void) crackWall: (SKSpriteNode *) wall {
//    if ((wall.physicsBody.categoryBitMask & PCPhysicsCategoryWall) != 0) {
//        NSArray * texture = @[[_bgLayer textureNamed:@"wall-cracked"],
//                              [_bgLayer textureNamed:@"wall"]];
//        SKAction * animate = [SKAction animateWithTextures:texture timePerFrame:2.0];
//        [wall runAction:animate  withKey:@"crackAnim"];
//        
//        
//        wall.physicsBody.categoryBitMask = PCPhysicsCategoryCrackedWall;
//        [wall runAction:[SKAction skt_afterDelay:2.0 runBlock:^{
//            wall.physicsBody.categoryBitMask = PCPhysicsCategoryWall;
//        }]];
//    } else if (wall.physicsBody.categoryBitMask & PCPhysicsCategoryCrackedWall) {
//        
//        [wall removeActionForKey:@"crackAnim"];
//        wall.texture = [_bgLayer textureNamed:@"wall-broken"];
//        wall.physicsBody = nil;
//    }
    if ((wall.physicsBody.categoryBitMask & PCPhysicsCategoryWall) != 0) {
        
        NSArray *textures = @[[_bgLayer textureNamed:@"wall-cracked"],
                              [_bgLayer textureNamed:@"wall"]];
        
        SKAction *animate = [SKAction animateWithTextures:textures timePerFrame:2.0];
        [wall runAction:animate withKey:@"crackAnim"];
        
        wall.physicsBody.categoryBitMask = PCPhysicsCategoryCrackedWall;
        [wall runAction:[SKAction skt_afterDelay:2.0 runBlock:^{
            wall.physicsBody.categoryBitMask = PCPhysicsCategoryWall;
        }]];
        
    } else if (wall.physicsBody.categoryBitMask & PCPhysicsCategoryCrackedWall) {
        
        [wall removeActionForKey:@"crackAnim"];
        wall.texture = [_bgLayer textureNamed:@"wall-broken"];
        wall.physicsBody = nil;
    }

}

- (void)bugHitEffects:(SKSpriteNode *)bug {
    // 1
    bug.physicsBody = nil;
    [bug removeAllActions];
    // 2
    SKNode *newNode = [SKNode node];
    [_bugLayer addChild:newNode];
    newNode.position = bug.position;
    bug.position = CGPointZero;
    [bug removeFromParent];
    [newNode addChild:bug];
    // 3
    const NSTimeInterval Duration = 1.3;
    [newNode runAction: [SKAction skt_removeFromParentAfterDelay:Duration]];
    // 4: Create and run special effects here!
    // moving
    [self scaleBug:newNode duration:Duration];
    [self rotateBug:newNode duration:Duration];
    [self fadeBug:newNode duration:Duration];
    [self bounceBug:newNode duration:Duration];
    
    bug.color = SKColorWithRGB(128, 128, 128);
    bug.colorBlendFactor = 1.0f;
    
    SKNode * maskNode = [SKSpriteNode spriteNodeWithTexture:bug.texture];
    [self flashBug:newNode mask:maskNode];
    
    [_worldNode runAction:[SKAction skt_screenShakeWithNode:_worldNode amount:CGPointMake(0.0f, -12.0f) oscillations:3 duration:1.0]];
    
    CFTimeInterval now = CACurrentMediaTime();
    if (now - _lastComboTime < 0.5f) {
        _comboCounter++;
    } else {
        _comboCounter = 0;
    }
    _lastComboTime = now;
    [newNode runAction:KillBugSounds[MIN(11, _comboCounter)]];
    
    // blode
    [self showParticlesForBug:newNode];
}

- (void)scaleBug:(SKNode *)node
        duration:(NSTimeInterval)duration
{
    const CGFloat ScaleFactor = 1.5f + _comboCounter * 0.25f;
    
    SKAction *scaleUp = [SKAction scaleTo:ScaleFactor
                                 duration:duration * 0.16667];
    scaleUp.timingMode = SKActionTimingEaseIn;
    
    SKAction *scaleDown = [SKAction scaleTo:0.0f
                                   duration:duration * 0.83335];
    scaleDown.timingMode = SKActionTimingEaseIn;
    
    [node runAction:[SKAction sequence:@[scaleUp, scaleDown]]];
}

- (void)rotateBug:(SKNode *)node
         duration:(NSTimeInterval)duration
{
    SKAction *rotateAction = [SKAction rotateByAngle:M_PI*6.0f
                                            duration:duration];
    [node runAction:rotateAction];
}

- (void)fadeBug:(SKNode *)node duration:(NSTimeInterval)duration
{
    SKAction *fadeAction =
    [SKAction fadeOutWithDuration:duration * 0.75];
    fadeAction.timingMode = SKActionTimingEaseIn;
    [node runAction:[SKAction skt_afterDelay:duration * 0.25
                                     perform:fadeAction]];
}

- (void)fireBugHitEffects
{
    SKAction *blink =
    [SKAction sequence:@[
                         [SKAction fadeOutWithDuration:0.0],
                         [SKAction waitForDuration:0.1],
                         [SKAction fadeInWithDuration:0.0],
                         [SKAction waitForDuration:0.1]]];
    
    [_player runAction:[SKAction repeatAction:blink count:4]];
    
    [_worldNode runAction:[SKAction skt_screenZoomWithNode:_worldNode amount:CGPointMake(1.05f, 1.05f) oscillations:6 duration:2.0]];
    [self colorGlitch];
    [self runAction:HitFireBugSound];
}

- (void)bounceBug:(SKNode *)node duration:(NSTimeInterval)duration
{
    CGPoint oldPosition = node.position;
    CGPoint upPosition = CGPointAdd(oldPosition, CGPointMake(0.0f, 80.0f));
    SKTMoveEffect *upEffect = [SKTMoveEffect effectWithNode:node duration:1.2 startPosition:oldPosition endPosition:upPosition];
    upEffect.timingFunction = ^(float t) {
        return powf(2.0f, -3.0f * t) * fabsf(sinf(t * M_PI * 3.0f));
    };
    SKAction *upAction = [SKAction actionWithEffect:upEffect];
    [node runAction:upAction];
}

- (void) flashBug: (SKNode *) node mask:(SKNode *)mask {
    SKCropNode * cropNode = [SKCropNode node];
    cropNode.maskNode = mask;
    
    SKSpriteNode * whiteNode = [SKSpriteNode spriteNodeWithColor:SKColorWithRGB(255, 255, 255) size:CGSizeMake(50, 50)];
    [cropNode addChild:whiteNode];
    
    [cropNode runAction:[SKAction sequence:@[[SKAction fadeInWithDuration:0.05],
                                             [SKAction fadeOutWithDuration:0.3]]]];
    [node addChild:cropNode];
}

- (void) screenShakeForSide: (Side) side power: (CGFloat) power {
    static CGPoint offsets[] = {
        { 1.0f, 0.0f },
        { 0.0f, 1.0f },
        { -1.0f, 0.0f },
        { 0.0f, -1.0f }
    };
    CGPoint amount = offsets[side];
    amount.x *= power;
    amount.y *= power;
    
    SKAction * action = [SKAction skt_screenShakeWithNode:_worldNode amount:amount oscillations:3 duration:1.0];
    [_worldNode runAction:action];
}

- (void)colorGlitch {
    // 1
    [_bgLayer enumerateChildNodesWithName:@"background" usingBlock:
     ^(SKNode *node, BOOL *stop) {
         node.hidden = YES;
     }];
    [self runAction:[SKAction sequence:@[
                                         // 2
         [SKAction skt_colorGlitchWithScene:self originalColor:SKColorWithRGB(89, 133, 39)
                                   duration:0.1],
         // 3
         [SKAction runBlock:^{
            [_bgLayer enumerateChildNodesWithName:@"background" usingBlock:
             ^(SKNode *node, BOOL *stop) {
                   node.hidden = NO;
           }];
    }]]]];
}

- (void) showParticlesForWall: (SKNode *)node onSide: (Side) side {
    CGPoint position = _player.position;
    if (side == SideRight) {
        position.x = node.position.x - _bgLayer.tileSize.width / 2.0f;
    } else if (side == SideLeft) {
        position.x = node.position.x + _bgLayer.tileSize.width / 2.0f;
    } else if (SideTop == side) {
        position.y = node.position.y - _bgLayer.tileSize.height / 2.0f;
    } else {
        position.y = node.position.y + _bgLayer.tileSize.height / 2.0f;
    }
    SKEmitterNode * emitter = [SKEmitterNode skt_emitterNamed:@"PlayerHitWall"];
    emitter.position = position;
    
    [emitter runAction:[SKAction skt_removeFromParentAfterDelay:1.0]];
    [_bgLayer addChild:emitter];
    if (node.physicsBody.categoryBitMask & PCPhysicsCategoryWater) {
        emitter.particleTexture = [SKTexture textureWithImageNamed:@"WaterDrop"];
    }
}

- (void) showTapAtLocation: (CGPoint)point {
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-3.0f, -3.0f, 6.0f, 6.0f)];
    SKShapeNode * shapeNode = [SKShapeNode node];
    shapeNode.path = path.CGPath;
    shapeNode.position = point;
    shapeNode.strokeColor = SKColorWithRGBA(255, 255, 255, 196);
    shapeNode.lineWidth = 1;
    shapeNode.antialiased = NO;
    [_worldNode addChild:shapeNode];
    
    const NSTimeInterval Duration = 0.6;
    SKAction * scaleAction = [SKAction scaleTo:6.0f duration:Duration];
    scaleAction.timingMode = SKActionTimingEaseOut;
    [shapeNode runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
    
    SKAction * fadeAction = [SKAction fadeOutWithDuration:Duration];
    fadeAction.timingMode = SKActionTimingEaseOut;
    [shapeNode runAction:fadeAction];
}

- (void) showParticlesForBug: (SKNode *) node {
    SKEmitterNode * emitter = [SKEmitterNode skt_emitterNamed:@"BugSplatter"];
    emitter.position = node.position;
    
    [emitter runAction:[SKAction skt_removeFromParentAfterDelay:0.4]];
    [_bgLayer addChild:emitter];
}
@end
