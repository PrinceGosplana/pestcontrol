//
//  TileMapLayer.h
//  pestcontrol
//
//  Created by Administrator on 31.07.14.
//  Copyright (c) 2014 Administrator. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface TileMapLayer : SKNode

@property (readonly, nonatomic) CGSize gridSize;
@property (readonly, nonatomic) CGSize layerSize;

@property (readonly, nonatomic) CGSize tileSize;

- (instancetype) initWithAtlasNamed: (NSString *) atlasName
                           tileSize: (CGSize) tileSize
                               grid: (NSArray *) grid;
- (BOOL) isValidTileCoord: (CGPoint) coord;
- (CGPoint) pointForcoord: (CGPoint) coord;
- (CGPoint) coordForPoint: (CGPoint) point;
- (SKNode *) tileAtCoord: (CGPoint) coord;
- (SKNode *) tileAtPoint: (CGPoint) point;
- (SKTexture *)textureNamed:(NSString *)name;

@end
