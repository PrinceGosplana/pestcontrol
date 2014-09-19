//
//  Breakable.h
//  PestControl2
//
//  Created by Oleksandr Isaiev on 30.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Breakable : SKSpriteNode

- (instancetype) initWithWhole: (SKTexture *) whole broken: (SKTexture *) broken flyAway:(SKTexture *)flyAway;
- (void) smashBreakable;

@end
