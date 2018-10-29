# [Dash for iOS](https://kapeli.com/dash_ios)

Dash gives your iPad and iPhone instant offline access to 150+ API documentation sets.

For more information about Dash, check out https://kapeli.com/dash_ios.

Also please check out [Dash for macOS](https://kapeli.com/dash).

## Installation Instructions

The recommended way of installing Dash is through the [App Store](https://itunes.apple.com/us/app/dash-offline-api-docs/id1239167694?mt=8).

Alternatively, you can use Xcode to install Dash on your iOS device using just your Apple ID.

All you need to do is:

1. Install [Xcode](https://developer.apple.com/xcode/download/)
1. Download the [Dash for iOS Source Code](https://github.com/Kapeli/Dash-iOS/releases/latest) or `git clone https://github.com/Kapeli/Dash-iOS.git`
1. Open "Dash iOS.xcworkspace" in Xcode
1. Go to Xcode's Preferences > Accounts and add your Apple ID
1. In Xcode's sidebar select "Dash iOS" and go to General > Identity. Append a word at the end of the *Bundle Identifier* e.g. com.kapeli.dash.ios*.name* so it's unique. Select your Apple ID in Signing > Team
1. Connect your iPad or iPhone using USB and select it in Xcode's Product menu > Destination
1. Press CMD+R or Product > Run to install Dash
1. If you install using a free (non-developer) account, make sure to rebuild Dash every 7 days, otherwise it will quit at launch when your certificate expires

[Contact me](https://kapeli.com/contact) if you need help.

## Contribution Guidelines

I am currently only accepting pull requests that fix bugs or add/improve features. I can't allocate time to review pull requests that only refactor things or add comments.

Try to maintain the same coding style I use (e.g. curly braces on their own line). I know it's a bit different from anyone else's and you might disagree with it, but having sections of code with a different style would make things worse.
