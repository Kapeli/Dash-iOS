UIActionSheet+Blocks
===================

Category on UIActionSheet to use inline block callbacks instead of delegate callbacks.

UIActionSheet was created in a time before blocks, ARC, and judging by its naming – touch screens too. Who “clicks” on an action sheet anyway?

Lets modernize this shizzle with some blocks goodness.

```objc
typedef void (^UIActionSheetBlock) (UIActionSheet *actionSheet);
typedef void (^UIActionSheetCompletionBlock) (UIActionSheet *actionSheet, NSInteger buttonIndex);

@property (copy, nonatomic) UIActionSheetCompletionBlock tapBlock;
@property (copy, nonatomic) UIActionSheetCompletionBlock willDismissBlock;
@property (copy, nonatomic) UIActionSheetCompletionBlock didDismissBlock;

@property (copy, nonatomic) UIActionSheetBlock willPresentBlock;
@property (copy, nonatomic) UIActionSheetBlock didPresentBlock;
@property (copy, nonatomic) UIActionSheetBlock cancelBlock;
```

You can create and show an action sheet in a single call, e.g.

```objc
[UIActionSheet showInView:self.view
                withTitle:@"Are you sure you want to delete all the things?"
        cancelButtonTitle:@"Cancel"
   destructiveButtonTitle:@"Delete all the things"
        otherButtonTitles:@[@"Just some of the things", @"Most of the things"]
                 tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                     NSLog(@"Chose %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
                 }];
```

The full suite of action methods are supported, including `showFromTabBar:`, `showFromToolbar:`, `showInView:`, `showFromBarButtonItem:animated:` and `showFromRect:inView:animated:`.

If you need further customization, you can create and configure an action sheet as you usually would, and then assign blocks to the action sheet, e.g.

```objc
UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Choose a coffee"
                                                delegate:nil
                                       cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Flat White", @"Latte", @"Cappuccino", @"Long Black", nil];

as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

as.tapBlock = ^(UIActionSheet *actionSheet, NSInteger buttonIndex){
    NSLog(@"Chose %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
};

[as showInView:self.view];
```

If a delegate was set on the action sheet, the delegate will be preserved and the blocks will be executed _before_ the delegate is called.

## Requirements

Blocks - so iOS 4.0 and later. Compatible with both ARC and traditional retain/release code.

## Usage

Add `UIActionSheet+Blocks.h/m` into your project, or `pod 'UIActionSheet+Blocks'` using CocoaPods.

## Alert Views

If you’d like similar functionality on UIAlertView too, check out twin-sister [UIAlertView+Blocks](https://github.com/ryanmaxwell/UIAlertView-Blocks).

## iOS 8 and UIAlertController

Check out [UIAlertController+Blocks](https://github.com/ryanmaxwell/UIAlertController-Blocks) if you would like to migrate to UIAlertController, and use a familiar API.