//
//  CustomActionSheet.h
//  Heard
//
//  Created by Baptiste Truchot on 7/31/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomActionSheet : UIActionSheet

- (void)addTitleViewWithUsername:(NSString *)username image:(UIImage *)image andOneTapBlock:(void(^)())oneTapBlock;

@end
