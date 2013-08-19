//
//  yukichiViewController.m
//  Proximity Sensor
//
//  Created by Ueta Shunya on 2013/08/19.
//  Copyright (c) 2013年 Ueta Shunya. All rights reserved.
//

#import "yukichiViewController.h"

@interface yukichiViewController ()

@end

@implementation yukichiViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


// 近接センサをONに
- (void)startSensor {
    // 近接センサをオン
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    // 近接センサ監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximitySensorStateDidchange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}

// 近接センサの値が変更
- (void)proximitySensorStateDidchange:(NSNotification *)notification {
    // センサに近づいたら踏み絵成功
    if ([UIDevice currentDevice].proximityState == YES) {
        // アラート出す
        NSString *message = @"おまえはApple教に入っていないな";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"踏み絵成功"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

- (void)stopSensor {
    // 近接センサオフ
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    // 近接センサ監視解除
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self startSensor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
