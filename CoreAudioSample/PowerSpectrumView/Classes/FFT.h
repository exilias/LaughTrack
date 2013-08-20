//
//  FFT.h
//  WhiteOut
//
//  Created by Norihisa Nagano
//

#import <Foundation/Foundation.h>


@interface FFT : NSObject {
    float *HanningWindow;
    float *imag;
    UInt32 _frameSize;
}

-(id)initWithFrameSize:(UInt32)frameSize;

-(void)calcPowerSpectrum:(float*)real  
           powerSpectrum:(float*)powerSpectrum;

-(void)setup;
@end