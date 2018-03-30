//
//  UIActionSheet+Blocks.h
//  UIActionSheetBlocks
//
//  Created by Ryan Maxwell on 31/08/13.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2013 Ryan Maxwell
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>

typedef void (^UIActionSheetBlock) (UIActionSheet * __nonnull actionSheet);
typedef void (^UIActionSheetCompletionBlock) (UIActionSheet * __nonnull actionSheet, NSInteger buttonIndex);

@interface UIActionSheet (Blocks)

+ (nonnull instancetype)showFromTabBar:(nonnull UITabBar *)tabBar
                     withTitle:(nullable NSString *)title
             cancelButtonTitle:(nullable NSString *)cancelButtonTitle
        destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
             otherButtonTitles:(nullable NSArray *)otherButtonTitles
                      tapBlock:(nullable UIActionSheetCompletionBlock)tapBlock;

+ (nonnull instancetype)showFromToolbar:(nonnull UIToolbar *)toolbar
                      withTitle:(nullable NSString *)title
              cancelButtonTitle:(nullable NSString *)cancelButtonTitle
         destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
              otherButtonTitles:(nullable NSArray *)otherButtonTitles
                       tapBlock:(nullable UIActionSheetCompletionBlock)tapBlock;

+ (nonnull instancetype)showInView:(nonnull UIView *)view
                 withTitle:(nullable NSString *)title
         cancelButtonTitle:(nullable NSString *)cancelButtonTitle
    destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
         otherButtonTitles:(nullable NSArray *)otherButtonTitles
                  tapBlock:(nullable UIActionSheetCompletionBlock)tapBlock;

+ (nonnull instancetype)showFromBarButtonItem:(nonnull UIBarButtonItem *)barButtonItem
                             animated:(BOOL)animated
                            withTitle:(nullable NSString *)title
                    cancelButtonTitle:(nullable NSString *)cancelButtonTitle
               destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
                    otherButtonTitles:(nullable NSArray *)otherButtonTitles
                             tapBlock:(nullable UIActionSheetCompletionBlock)tapBlock;

+ (nonnull instancetype)showFromRect:(CGRect)rect
                      inView:(nonnull UIView *)view
                    animated:(BOOL)animated
                   withTitle:(nullable NSString *)title
           cancelButtonTitle:(nullable NSString *)cancelButtonTitle
      destructiveButtonTitle:(nullable NSString *)destructiveButtonTitle
           otherButtonTitles:(nullable NSArray *)otherButtonTitles
                    tapBlock:(nullable UIActionSheetCompletionBlock)tapBlock;

@property (copy, nonatomic, nullable) UIActionSheetCompletionBlock tapBlock;
@property (copy, nonatomic, nullable) UIActionSheetCompletionBlock willDismissBlock;
@property (copy, nonatomic, nullable) UIActionSheetCompletionBlock didDismissBlock;

@property (copy, nonatomic, nullable) UIActionSheetBlock willPresentBlock;
@property (copy, nonatomic, nullable) UIActionSheetBlock didPresentBlock;
@property (copy, nonatomic, nullable) UIActionSheetBlock cancelBlock;

@end
