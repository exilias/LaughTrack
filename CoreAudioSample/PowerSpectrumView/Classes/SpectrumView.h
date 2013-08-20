//
//  SpectrumView.h
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import <UIKit/UIKit.h>


@interface SpectrumView : UIView {
    UInt32 bandSize;
    float *powerSpectrum;
    BOOL initialized;
}

-(void)setSpectrum:(float*)spectrum bandSize:(UInt32)size;

@end