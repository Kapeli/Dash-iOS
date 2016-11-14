Change Log
==========

This is the history of version updates.

**Version 1.1.1**

- FIXED: Various Xcode warnings
- FIXED: Issue when initializing on older iOS (<7.0) or OSX (<10.9) version
- CHANGED: run loop scheduling to common modes

**Version 1.1.0**

- FIXED: Various type warnings
- ADDED: New method on DTBonjourDataConnection which allows specifying a timeout
- ADDED: Delegate method for when connection was opened
- ADDED: arm64 support
- CHANGED: Updated for building with Xcode 5
- CHANGED: Use original NSNetService method to get connection where workaround no longer necessary

**Version 1.0.0**

Initial release