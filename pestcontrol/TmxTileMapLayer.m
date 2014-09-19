//
//  TmxTileMapLayer.m
//  PestControl2
//
//  Created by Oleksandr Isaiev on 31.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import "TmxTileMapLayer.h"

@implementation TmxTileMapLayer {
    TMXLayer * _layer;
    CGSize _tmxTileSize;
    CGSize _tmxGridSize;
    CGSize _tmxLayerSize;
}

- (instancetype)initWithTmxLayer:(TMXLayer *)layer {
    if (self = [super init]) {
        _layer = layer;
        _tmxTileSize = layer.mapTileSize;
        _tmxGridSize = layer.layerInfo.layerGridSize;
        _tmxLayerSize = CGSizeMake(layer.layerWidth, layer.layerHeight);
    }
    return self;
}

- (CGSize) gridSize {
    return _tmxGridSize;
}

- (CGSize) tileSize {
    return _tmxTileSize;
}

- (CGSize) layerSize {
    return _tmxLayerSize;
}

#pragma mark Saving and loading state

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_layer forKey:@"TmxTML-Layer"];
    [aCoder encodeCGSize:_tmxTileSize forKey:@"TmxTML-TileSize"];
    [aCoder encodeCGSize:_tmxGridSize forKey:@"TmxTML-GridSize"];
    [aCoder encodeCGSize:_tmxLayerSize forKey:@"TmxTML-LayerSize"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _layer = [aDecoder decodeObjectForKey:@"TmxTML-Layer"];
        _tmxTileSize = [aDecoder decodeCGSizeForKey:@"TmxTML-TileSize"];
        _tmxGridSize = [aDecoder decodeCGSizeForKey:@"TmxTML-GridSize"];
        _tmxLayerSize = [aDecoder decodeCGSizeForKey:@"TmxTML-LayerSize"];
    }
    return self;
}
@end
