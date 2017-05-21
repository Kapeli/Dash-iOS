[![Build Status](https://travis-ci.org/nicklockwood/GZIP.svg)](https://travis-ci.org/nicklockwood/GZIP)


Purpose
--------------

GZIP is category on NSData that provides simple gzip compression and decompression functionality.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 10.3 / Mac OS 10.12 (Xcode 8.3)
* Earliest supported deployment target - iOS 8.0 / Mac OS 10.9
* Earliest compatible deployment target - iOS 8.0 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

The GZIP category will work correctly in either ARC or non-ARC projects without modification.


Thread Safety
--------------

All the GZIP methods should be safe to call from multiple threads concurrently.


Installation
--------------

The simplest way to install GZIP is to use CocoaPods, by adding the following to your Podfile:

	pod 'GZIP', '~> 1.2'

Alternatively you can use Carthage, or if you prefer to install manually, drag the GZIP.xcodeproj into your project or workspace and include GZIP.framework under the linked libraries in your target.


NSData Extensions
----------------------

    - (NSData *)gzippedDataWithCompressionLevel:(float)level;

This method will apply the gzip deflate algorithm and return the compressed data. The compression level is a floating point value between 0.0 and 1.0, with 0.0 meaning no compression and 1.0 meaning maximum compression.  A value of 0.1 will provide the fastest possible compression. If you supply a negative value, this will apply the default compression level, which is equivalent to a value of around 0.7.

    - (NSData *)gzippedData;
    
This method is equivalent to calling `gzippedDataWithCompressionLevel:` with the default compression level.
    
    - (NSData *)gunzippedData;
    
This method will unzip data that was compressed using the deflate algorithm and return the result.

    - (BOOL)isGzippedData;
    
This method will return YES if the data is gzip-encoded.


Release Notes
--------------

Version 1.2

- Removed dlopen, as Apple have begun rejecting apps that use it.
- Minimum deployment target is now iOS 8.0.
- Added watchOS / tvOS support.
- Added Carthage support.

Version 1.1.1

- Fixed crash on iOS 9.
- Added performance tests.

Version 1.1

- Added `isGzippedData` method.
- GZIP will no longer re-encode already-gzipped data, nor try  (and fail) to decode ungzipped data.
- GZIP now uses dlopen to load the libz.dylib at runtime, so there's no need to include it manually in your project.
- Fixed warnings and errors on Xcode 7

Version 1.0.3

- Fixed new warnings in Xcode 6
- Added Travis CI support

Version 1.0.2

- Now complies with -Weverything warning level

Version 1.0.1

- Added podspec
- Renamed source files
- Verified compliance with iOS 7 / Mac OS 10.8
- Verified compliance with -Wextra warning level

Version 1.0

- Initial release.