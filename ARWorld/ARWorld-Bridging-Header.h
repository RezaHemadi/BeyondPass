//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Parse/Parse.h>

#import <Foundation/Foundation.h>
#import <SceneKit/Scenekit.h>
#import <CommonCrypto/CommonCrypto.h>

@protocol TAProgressLayerProtocol <NSObject>

- (void)progressUpdatedTo:(CGFloat)progress;

@end

@interface TAProgressLayer : CALayer

@property CGFloat progress;
@property (weak) id<TAProgressLayerProtocol> delegate;

@end

@implementation TAProgressLayer

// We must copy across our custom properties since Core Animation makes a copy
// of the layer that it's animating.

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self) {
        TAProgressLayer *otherLayer = (TAProgressLayer *)layer;
        self.progress = otherLayer.progress;
        self.delegate = otherLayer.delegate;
    }
    return self;
}

// Override needsDisplayForKey so that we can define progress as being animatable.

+ (BOOL)needsDisplayForKey:(NSString*)key {
    if ([key isEqualToString:@"progress"]) {
        return YES;
    } else {
        return [super needsDisplayForKey:key];
    }
}

// Call our callback

- (void)drawInContext:(CGContextRef)ctx
{
    if (self.delegate)
    {
        [self.delegate progressUpdatedTo:self.progress];
    }
}

@end
