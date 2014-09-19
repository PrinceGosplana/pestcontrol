//
//  Player.h
//  PestControl2
//
//  Created by Oleksandr Isaiev on 28.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AnimatingSprite.h"

@interface Player : AnimatingSprite {
    SKEmitterNode * _emitter;
}

- (void) moveToward: (CGPoint) targetPosition;
- (void) faceCurrentDirection;
- (void) start;

@end
