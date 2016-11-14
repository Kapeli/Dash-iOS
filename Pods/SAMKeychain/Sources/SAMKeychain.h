//
//  SAMKeychain.h
//  SAMKeychain
//
//  Created by Sam Soffes on 5/19/10.
//  Copyright (c) 2010-2014 Sam Soffes. All rights reserved.
//

#if __has_feature(modules)
	@import Foundation;
#else
	#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Error code specific to SAMKeychain that can be returned in NSError objects.
 For codes returned by the operating system, refer to SecBase.h for your
 platform.
 */
typedef NS_ENUM(OSStatus, SAMKeychainErrorCode) {
	/** Some of the arguments were invalid. */
	SAMKeychainErrorBadArguments = -1001,
};

/** SAMKeychain error domain */
extern NSString *const kSAMKeychainErrorDomain;

/** Account name. */
extern NSString *const kSAMKeychainAccountKey;

/**
 Time the item was created.

 The value will be a string.
 */
extern NSString *const kSAMKeychainCreatedAtKey;

/** Item class. */
extern NSString *const kSAMKeychainClassKey;

/** Item description. */
extern NSString *const kSAMKeychainDescriptionKey;

/** Item label. */
extern NSString *const kSAMKeychainLabelKey;

/** Time the item was last modified.

 The value will be a string.
 */
extern NSString *const kSAMKeychainLastModifiedKey;

/** Where the item was created. */
extern NSString *const kSAMKeychainWhereKey;

/**
 Simple wrapper for accessing accounts, getting passwords, setting passwords, and deleting passwords using the system
 Keychain on Mac OS X and iOS.

 This was originally inspired by EMKeychain and SDKeychain (both of which are now gone). Thanks to the authors.
 SAMKeychain has since switched to a simpler implementation that was abstracted from [SSToolkit](http://sstoolk.it).
 */
@interface SAMKeychain : NSObject

#pragma mark - Classic methods

/**
 Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't have a
 password for the given parameters.

 @param serviceName The service for which to return the corresponding password.

 @param account The account for which to return the corresponding password.

 @return Returns a string containing the password for a given account and service, or `nil` if the Keychain doesn't
 have a password for the given parameters.
 */
+ (nullable NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account;
+ (nullable NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error __attribute__((swift_error(none)));

/**
 Returns a nsdata containing the password for a given account and service, or `nil` if the Keychain doesn't have a
 password for the given parameters.

 @param serviceName The service for which to return the corresponding password.

 @param account The account for which to return the corresponding password.

 @return Returns a nsdata containing the password for a given account and service, or `nil` if the Keychain doesn't
 have a password for the given parameters.
 */
+ (nullable NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account;
+ (nullable NSData *)passwordDataForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error __attribute__((swift_error(none)));


/**
 Deletes a password from the Keychain.

 @param serviceName The service for which to delete the corresponding password.

 @param account The account for which to delete the corresponding password.

 @return Returns `YES` on success, or `NO` on failure.
 */
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error __attribute__((swift_error(none)));


/**
 Sets a password in the Keychain.

 @param password The password to store in the Keychain.

 @param serviceName The service for which to set the corresponding password.

 @param account The account for which to set the corresponding password.

 @return Returns `YES` on success, or `NO` on failure.
 */
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error __attribute__((swift_error(none)));

/**
 Sets a password in the Keychain.

 @param password The password to store in the Keychain.

 @param serviceName The service for which to set the corresponding password.

 @param account The account for which to set the corresponding password.

 @return Returns `YES` on success, or `NO` on failure.
 */
+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account;
+ (BOOL)setPasswordData:(NSData *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError **)error __attribute__((swift_error(none)));

/**
 Returns an array containing the Keychain's accounts, or `nil` if the Keychain has no accounts.

 See the `NSString` constants declared in SAMKeychain.h for a list of keys that can be used when accessing the
 dictionaries returned by this method.

 @return An array of dictionaries containing the Keychain's accounts, or `nil` if the Keychain doesn't have any
 accounts. The order of the objects in the array isn't defined.
 */
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)allAccounts;
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)allAccounts:(NSError *__autoreleasing *)error __attribute__((swift_error(none)));


/**
 Returns an array containing the Keychain's accounts for a given service, or `nil` if the Keychain doesn't have any
 accounts for the given service.

 See the `NSString` constants declared in SAMKeychain.h for a list of keys that can be used when accessing the
 dictionaries returned by this method.

 @param serviceName The service for which to return the corresponding accounts.

 @return An array of dictionaries containing the Keychain's accounts for a given `serviceName`, or `nil` if the Keychain
 doesn't have any accounts for the given `serviceName`. The order of the objects in the array isn't defined.
 */
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)accountsForService:(nullable NSString *)serviceName;
+ (nullable NSArray<NSDictionary<NSString *, id> *> *)accountsForService:(nullable NSString *)serviceName error:(NSError *__autoreleasing *)error __attribute__((swift_error(none)));


#pragma mark - Configuration

#if __IPHONE_4_0 && TARGET_OS_IPHONE
/**
 Returns the accessibility type for all future passwords saved to the Keychain.

 @return Returns the accessibility type.

 The return value will be `NULL` or one of the "Keychain Item Accessibility
 Constants" used for determining when a keychain item should be readable.

 @see setAccessibilityType
 */
+ (CFTypeRef)accessibilityType;

/**
 Sets the accessibility type for all future passwords saved to the Keychain.

 @param accessibilityType One of the "Keychain Item Accessibility Constants"
 used for determining when a keychain item should be readable.

 If the value is `NULL` (the default), the Keychain default will be used which
 is highly insecure. You really should use at least `kSecAttrAccessibleAfterFirstUnlock`
 for background applications or `kSecAttrAccessibleWhenUnlocked` for all
 other applications.

 @see accessibilityType
 */
+ (void)setAccessibilityType:(CFTypeRef)accessibilityType;
#endif

@end

NS_ASSUME_NONNULL_END

#import <SAMKeychain/SAMKeychainQuery.h>
