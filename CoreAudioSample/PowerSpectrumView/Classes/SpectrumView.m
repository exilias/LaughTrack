//
//  SpectrumView.m
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import "SpectrumView.h"


@implementation SpectrumView

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}


-(void)setSpectrum:(float*)spectrum bandSize:(UInt32)size{
    if(bandSize != size){
        bandSize = size;
        if(powerSpectrum)free(powerSpectrum);
        powerSpectrum = malloc(sizeof(float) * bandSize);
        initialized = YES;
    }    
    memcpy(powerSpectrum, spectrum, sizeof(float) * bandSize);
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();    
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, rect);
    
    if(!initialized){
        return;
    }
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1);
    float xunit = rect.size.width / bandSize;
    float yunit = rect.size.height / -150; //-100dBで打ち切り
    float blockSize = xunit;
    
    //dbは、-120〜0なので、-掛ければいいか
    
    for(int i = 0; i < bandSize; i++){
        float power = powerSpectrum[i];
        float dB = -100;
        if(power > 0.00001){
            dB = 20 * log(power/bandSize);
        }
        float y = dB * yunit;
        CGRect fillRect = CGRectMake(xunit * i,
                                     y, 
                                     blockSize,
                                     rect.size.height - y);
        CGContextFillRect(context, fillRect);
    }
}


- (void)dealloc{
    [super dealloc];
}

@end