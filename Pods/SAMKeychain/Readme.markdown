# SAMKeychain

SAMKeychain is a simple wrapper for accessing accounts, getting passwords, setting passwords, and deleting passwords using the system Keychain on Mac OS X and iOS.

## Adding to Your Project

Simply add the following to your Podfile if you're using CocoaPods:

``` ruby
pod 'SAMKeychain'
```

or Cartfile if you're using Carthage:

```
github "soffes/SAMKeychain"
```

To manually add to your project:

1. Add `Security.framework` to your target
2. Add `SAMKeychain.h`, `SAMKeychain.m`, `SAMKeychainQuery.h`, and `SAMKeychainQuery.m` to your project.

SAMKeychain requires ARC.

Note: Currently SAMKeychain does not support Mac OS 10.6.

## Working with the Keychain

SAMKeychain has the following class methods for working with the system keychain:

```objective-c
+ (NSArray *)allAccounts;
+ (NSArray *)accountsForService:(NSString *)serviceName;
+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account;
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType;
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account;
```

Easy as that. (See [SAMKeychain.h](https://github.com/soffes/samkeychain/blob/master/Sources/SAMKeychain.h) and [SAMKeychainQuery.h](https://github.com/soffes/samkeychain/blob/master/Sources/SAMKeychainQuery.h) for all of the methods.)


## Documentation

### Use prepared documentation

Read the [online documentation](http://cocoadocs.org/docsets/SAMKeychain).

## Debugging

If your saving to the keychain fails, use the NSError object to handle it. You can invoke `[error code]` to get the numeric error code. A few values are defined in SAMKeychain.h, and the rest in SecBase.h.

```objective-c
NSError *error = nil;
SAMKeychainQuery *query = [[SAMKeychainQuery alloc] init];
query.service = @"MyService";
query.account = @"soffes";
[query fetch:&error];

if ([error code] == errSecItemNotFound) {
    NSLog(@"Password not found");
} else if (error != nil) {
	NSLog(@"Some other error occurred: %@", [error localizedDescription]);
}
```

Obviously, you should do something more sophisticated. You can just call `[error localizedDescription]` if all you need is the error message.

## Disclaimer

Working with the keychain is pretty sucky. You should really check for errors and failures. This library doesn't make it any more stable, it just wraps up all of the annoying C APIs.

You also really should not use the default but set the `accessibilityType`.
`kSecAttrAccessibleWhenUnlocked` should work for most applications. See
[Apple Documentation](https://developer.apple.com/library/ios/DOCUMENTATION/Security/Reference/keychainservices/Reference/reference.html#//apple_ref/doc/constant_group/Keychain_Item_Accessibility_Constants)
for other options.

## Thanks

This was originally inspired by EMKeychain and SDKeychain (both of which are now gone). Thanks to the authors. SAMKeychain has since switched to a simpler implementation that was abstracted from [SSToolkit](http://sstoolk.it).

A huge thanks to [Caleb Davenport](https://github.com/calebd) for leading the way on version 1.0 of SAMKeychain.
