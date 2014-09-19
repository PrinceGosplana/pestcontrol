#import "TileMapLayer.h"
#import "JSTileMap.h"

@interface TmxTileMapLayer : TileMapLayer

- (instancetype) initWithTmxLayer: (TMXLayer *) layer;

@end
