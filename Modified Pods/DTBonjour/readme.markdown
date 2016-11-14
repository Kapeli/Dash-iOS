About DTBonjour
==================

[![Build Status](https://travis-ci.org/Cocoanetics/DTBonjour.png?branch=develop)](https://travis-ci.org/Cocoanetics/DTFoundation) [![Coverage Status](https://coveralls.io/repos/Cocoanetics/DTFoundation/badge.png?branch=develop)](https://coveralls.io/r/Cocoanetics/DTBonjour?branch=develop)

DTBonjour had its origin when I wanted communicate between a Mac app and an iOS app. It greatly simplifies networking over WiFi by giving you an easy method to transmit any NSObject that conforms to NSCoding.

Documentation
-------------

Documentation can be [browsed online](https://docs.cocoanetics.com/DTBonjour) or installed in your Xcode Organizer via the [Atom Feed URL](https://docs.cocoanetics.com/DTBonjour/DTBonjour).

Here is a [tutorial](http://www.cocoanetics.com/2012/11/and-bonjour-to-you-too/) on how to build a simple chat app with DTBonjour.

Usage
-----

You have these options of including DTBonjour in your project

- DTBonjour on CocoaPods
- include the git repo as a submodule
- clone a copy of it into an Externals folder in your project tree

When not using CocoaPods these are the steps for setup:

- include the xcodeproj as a sub-project
- Add the ObjC and all_load linker flags
- add a dependency to the static library for your platform
- add the static library also to the linking phase
- add a User Header Search Path into the location where you have the code

License
-------

It is open source and covered by a standard 2-clause BSD license. That means you have to mention *Cocoanetics* as the original author of this code and reproduce the LICENSE text inside your app. 

You can purchase a [Non-Attribution-License](https://www.cocoanetics.com/order/?product_id=DTBonjour) for 75 Euros for not having to include the LICENSE text.

We also accept sponsorship for specific enhancements which you might need. Please [contact us via email](mailto:oliver@cocoanetics.com?subject=DTBonjour) for inquiries.
