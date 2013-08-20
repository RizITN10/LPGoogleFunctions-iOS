//
//  LPMainViewController.h
//  StaticMapImagesService
//
//  Created by Luka Penger on 8/20/13.
//  Copyright (c) 2013 Luka Penger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LPGoogleFunctions.h"

@interface LPMainViewController : UIViewController <LPGoogleFunctionsDelegate>

@property (nonatomic, strong) LPGoogleFunctions *googleFunctions;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@end
