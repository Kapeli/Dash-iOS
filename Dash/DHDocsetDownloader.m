//
//  Copyright (C) 2016  Kapeli
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "DHDocsetDownloader.h"
#import "DHAppDelegate.h"
#import "DHFeed.h"
#import "DDXML.h"
#import "DHFeedResult.h"
#import "DHDocsetManager.h"

@implementation DHDocsetDownloader

static id singleton = nil;

- (void)setUp // doesn't get called unless you call the singleton from DHAppDelegate
{    
    [super setUp];
    NSMutableArray *dashFeeds = [NSMutableArray arrayWithObjects:[DHFeed feedWithFeed:@"NET_Framework.xml" icon:@"net" aliases:@[@"Microsoft .NET Framework", @"C#", @"f#", @"vb", @"visual basic", @"visualbasic", @"vstudio", @"visual studio", @"msdn", @"Microsoft Developer Network"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ActionScript.xml" icon:@"actionscript" aliases:@[@"adobe flash as3"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Akka.xml" icon:@"akka" aliases:@[@"scala"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Android.xml" icon:@"android" aliases:@[@"java"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Angular.xml" icon:@"angular" aliases:@[@"google angularjs", @"google angular.js", @"angular2", @"angular 2", @"angularjs 2", @"angular.js 2", @"google angularts", @"angular.io angular for typescript angular for ts angular.typescript angular.ts angulartypescript", @"google angular.ts", @"angular2", @"angular 2", @"angularts 2", @"angular.ts 2"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"AngularJS.xml" icon:@"angularjs" aliases:@[@"google angularjs", @"google angular.js", @"angular", @"angularjs", @"angular.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ansible.xml" icon:@"ansible" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Apache_HTTP_Server.xml" icon:@"apache" aliases:@[@"httpd"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Appcelerator_Titanium.xml" icon:@"titanium" aliases:@[@"Appcelerator Platform"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Apple_API_Reference.xml" icon:@"apple" aliases:@[@"leopard", @"snow leopard", @"lion", @"mountain lion", @"mavericks", @"yosemite", @"macos sierra", @"10.10", @"10.8", @"10.6", @"mac osx", @"10.7", @"10.9", @"10.5", @"xcode", @"apple", @"cocoa", @"objective-c", @"objc", @"macosx", @"macos x", @"swift", @"iphone", @"ipad", @"cocoa touch", @"tvos", @"tvservices", @"apple tv", @"ios", @"iphoneos", @"watchkit"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"AppleScript.xml" icon:@"applescript" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Arduino.xml" icon:@"arduino" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"AWS_JavaScript.xml" icon:@"awsjs" aliases:@[@"aws nodejs", @"aws node.js", @"amazon"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"BackboneJS.xml" icon:@"backbone" aliases:@[@"backbone.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Bash.xml" icon:@"bash" aliases:@[@"bash shell", @"terminal"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Boost.xml" icon:@"boost" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Bootstrap_2.xml" icon:@"bootstrap" aliases:@[@"twitter bootstrap"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Bootstrap_3.xml" icon:@"bootstrap" aliases:@[@"twitter bootstrap"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Bootstrap_4.xml" icon:@"bootstrap" aliases:@[@"twitter bootstrap"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Bourbon.xml" icon:@"bourbon" aliases:@[@"ruby gems", @"rubygems"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"C.xml" icon:@"c" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"C++.xml" icon:@"cpp" aliases:@[@"cpp"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"CakePHP.xml" icon:@"cakephp" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Cappuccino.xml" icon:@"cappuccino" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Chai.xml" icon:@"chai" aliases:@[@"chaijs assertion library", @"chai.js assertion library", @"chai assertion library", @"nodejs", @"node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Chef.xml" icon:@"chef" aliases:@[@"opscode chef"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Clojure.xml" icon:@"clojure" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"CMake.xml" icon:@"cmake" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Cocos2D.xml" icon:@"cocos2d" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Cocos2D-X.xml" icon:@"cocos2dx" aliases:@[@"cocos2dx", @"cocos2d_x"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Cocos3D.xml" icon:@"cocos2d" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"CodeIgniter.xml" icon:@"codeigniter" aliases:@[@"ellislab codeigniter", @"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"CoffeeScript.xml" icon:@"coffee" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ColdFusion.xml" icon:@"cf" aliases:@[@"adobe coldfusion", @"cfml"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Common_Lisp.xml" icon:@"lisp" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Compass.xml" icon:@"compass" aliases:@[@"ruby gems", @"rubygems"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Cordova.xml" icon:@"cordova" aliases:@[@"Apache Cordova", @"adobe PhoneGap"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Corona.xml" icon:@"corona" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"CouchDB.xml" icon:@"couchdb" aliases:@[@"Apache CouchDB"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Craft.xml" icon:@"craft" aliases:@[@"craft cms", @"craftcms.com", @"buildwithcraft.com", @"build with craft cms", @"php", @"yii2"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"CSS.xml" icon:@"css" aliases:@[@"mdn", @"mozilla developer network"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"D3JS.xml" icon:@"d3" aliases:@[@"d3.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Dart.xml" icon:@"dartlang" aliases:@[@"dart.js", @"dartjs", @"dartlang", @"dart.js lang", @"dart lang", @"dartjs lang"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Django.xml" icon:@"django" aliases:@[@"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Doctrine_ORM.xml" icon:@"doctrine" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Docker.xml" icon:@"docker" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Dojo.xml" icon:@"dojo" aliases:@"dojo toolkit" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"DOM.xml" icon:@"dom" aliases:@[@"dom events", @"mdn", @"mozilla developer network"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Drupal_7.xml" icon:@"drupal" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Drupal_8.xml" icon:@"drupal" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ElasticSearch.xml" icon:@"elasticsearch" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Elixir.xml" icon:@"elixir" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Emacs_Lisp.xml" icon:@"elisp" aliases:@[@"elisp"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"EmberJS.xml" icon:@"ember" aliases:@[@"ember-data", @"ember data"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Emmet.xml" icon:@"emmet" aliases:@[@"emmet.io", @"emmetio"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Erlang.xml" icon:@"erlang" aliases:@[@"Erlang OTP"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Express.xml" icon:@"express" aliases:@[@"expressjs", @"nodejs", @"node.js", @"express.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ExpressionEngine.xml" icon:@"ee" aliases:@[@"ellislab expressionengine ee", @"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ExtJS.xml" icon:@"extjs" aliases:@[@"sencha extjs", @"sencha ext.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Flask.xml" icon:@"flask" aliases:@[@"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Font_Awesome.xml" icon:@"awesome" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Foundation.xml" icon:@"foundation" aliases:@"zurb foundation" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"GLib.xml" icon:@"glib" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Go.xml" icon:@"go" aliases:@[@"google golang"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Gradle_DSL.xml" icon:@"gradle" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Gradle_Java_API.xml" icon:@"gradle" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Gradle_User_Guide.xml" icon:@"gradle" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Grails.xml" icon:@"grails" aliases:@[@"java"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Groovy.xml" icon:@"groovy" aliases:@[@"java"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Groovy_JDK.xml" icon:@"groovy" aliases:@[@"java"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Grunt.xml" icon:@"grunt" aliases:@[@"nodejs", @"node.js", @"grunt.js", @"gruntjs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Gulp.xml" icon:@"gulp" aliases:@[@"nodejs", @"node.js", @"gulp.js", @"gulpjs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Haml.xml" icon:@"haml" aliases:@[@"ruby gems", @"rubygems"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Handlebars.xml" icon:@"handlebars" aliases:@[@"nodejs", @"node.js", @"handlebars.js", @"handlebarsjs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Haskell.xml" icon:@"haskell" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"HTML.xml" icon:@"html" aliases:@[@"mdn", @"mozilla developer network"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Ionic.xml" icon:@"ionic" aliases:@[@"ionic framework"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"iOS.xml" icon:@"iphone" aliases:@[@"iphone", @"ipad", @"xcode", @"apple", @"cocoa touch", @"objective-c", @"objc", @"swift"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Jasmine.xml" icon:@"jasmine" aliases:@[@"jasminejs", @"jasmine.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Java_EE6.xml" icon:@"jee6" aliases:@[@"javaee6", @"jee6"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_EE7.xml" icon:@"jee7" aliases:@[@"javaee7", @"jee7"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_EE8.xml" icon:@"jee8" aliases:@[@"javaee8", @"jee8"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE6.xml" icon:@"java" aliases:@[@"javase6"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE7.xml" icon:@"java" aliases:@[@"javase7"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE8.xml" icon:@"java" aliases:@[@"javase8"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE9.xml" icon:@"java" aliases:@[@"javase9", @"javafx"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE10.xml" icon:@"java" aliases:@[@"javase10", @"javafx"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Java_SE11.xml" icon:@"java" aliases:@[@"javase11", @"javafx"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"JavaScript.xml" icon:@"javascript" aliases:@[@"mdn", @"mozilla developer network", @"dom events", @"canvas", @"js"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Jekyll.xml" icon:@"jekyll" aliases:@[@"jekyllrb jekyll.rb jekyll ruby"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Jinja.xml" icon:@"jinja" aliases:@[@"python jinja2 template engine jinja 2 template engine"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Joomla.xml" icon:@"joomla" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"jQuery.xml" icon:@"jQuery" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"jQuery_Mobile.xml" icon:@"jquerym" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"jQuery_UI.xml" icon:@"jqueryui" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Julia.xml" icon:@"julia" aliases:@[@"julialang"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"KnockoutJS.xml" icon:@"knockout" aliases:@[@"knockout.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Kobold2D.xml" icon:@"kobold2d" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"LaTeX.xml" icon:@"latex" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Laravel.xml" icon:@"laravel" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Less.xml" icon:@"less" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Lo-Dash.xml" icon:@"lodash" aliases:@[@"lodash"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Lua_5.1.xml" icon:@"lua" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Lua_5.2.xml" icon:@"lua" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Lua_5.3.xml" icon:@"lua" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"MarionetteJS.xml" icon:@"marionette" aliases:@[@"backbone marionette.js", @"backbone.marionette.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Markdown.xml" icon:@"markdown" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"MatPlotLib.xml" icon:@"matplotlib" aliases:@[@"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Meteor.xml" icon:@"meteor" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Mocha.xml" icon:@"mocha" aliases:@[@"mochajs mocha.js", @"nodejs", @"node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"MomentJS.xml" icon:@"moment" aliases:@[@"moment.js", @"nodejs", @"node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"MongoDB.xml" icon:@"mongodb" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Mongoose.xml" icon:@"mongoose" aliases:@[@"nodejs", @"node.js", @"mongoose.js", @"mongoosejs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Mono.xml" icon:@"mono" aliases:@[@"xamarin", @"mono touch", @"monotouch", @"monoios", @"mono for ios", @"mono android", @"monoandroid", @"mono for android", @"mono mac", @"monomac", @"mono for mac", @"monoosx", @"mono osx", @"mono for osx", @"xamarin.ios", @"xamarin.mac", @"xamarin.android", @"xamarin.osx", @"xamarin ios", @"xamarin mac", @"xamarin android", @"xamarin osx", @"xamarin for ios", @"xamarin for mac", @"xamarin for android", @"xamarin for osx"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"MooTools.xml" icon:@"moo" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"MySQL.xml" icon:@"mysql" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Neat.xml" icon:@"neat" aliases:@[@"bourbon neat", @"ruby gems", @"rubygems"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Nginx.xml" icon:@"nginx" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"NodeJS.xml" icon:@"nodejs" aliases:@[@"node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"NumPy.xml" icon:@"numpy" aliases:@[@"scipy", @"sci.py", @"num.py", @"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"OCaml.xml" icon:@"ocaml" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"OpenCV.xml" icon:@"opencv" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"OpenGL_2.xml" icon:@"gl2" aliases:@[@"opengl2"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"OpenGL_3.xml" icon:@"gl3" aliases:@[@"opengl3"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"OpenGL_4.xml" icon:@"gl4" aliases:@[@"opengl4 glsl openglsl"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"macOS.xml" icon:@"Mac" aliases:@[@"leopard", @"snow leopard", @"lion", @"mountain lion", @"mavericks", @"yosemite", @"10.10", @"10.8", @"10.6", @"mac osx", @"mac os x", @"10.7", @"10.9", @"10.5", @"xcode", @"apple", @"cocoa", @"macosx", @"macos x", @"objective-c", @"objc", @"swift"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Pandas.xml" icon:@"pandas" aliases:@[@"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Perl.xml" icon:@"perl" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Phalcon.xml" icon:@"phalcon" aliases:@[@"cphalcon", @"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"PhoneGap.xml" icon:@"phonegap" aliases:@"Apache Cordova adobe phonegap" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"PHP.xml" icon:@"php" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"PHPUnit.xml" icon:@"phpunit" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Play_Java.xml" icon:@"playjava" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Play_Scala.xml" icon:@"playscala" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Polymer.dart.xml" icon:@"polymerdart" aliases:@[@"polymer.dart.js", @"polymer.dartjs", @"polymer.dartlang", @"polymer.dart.js lang", @"polymer.dart lang", @"polymer.dartjs lang"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"PostgreSQL.xml" icon:@"psql" aliases:@[@"psql"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Processing.xml" icon:@"processing" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"PrototypeJS.xml" icon:@"prototype" aliases:@[@"prototype.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Pug.xml" icon:@"pug" aliases:@[@"jade", @"node.js", @"nodejs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Puppet.xml" icon:@"puppet" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Python_2.xml" icon:@"python" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Python_3.xml" icon:@"python" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Qt_4.xml" icon:@"qt" aliases:@[@"qt4"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Qt_5.xml" icon:@"qt" aliases:@[@"qt5"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"R.xml" icon:@"r" aliases:@[@"r language", @"r project", @"gnu s", @"rlanguage"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Racket.xml" icon:@"racket" aliases:@[@"racketlang racket-lang"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"React.xml" icon:@"react" aliases:@[@"facebook react.js reactjs"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Redis.xml" icon:@"redis" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"RequireJS.xml" icon:@"require" aliases:@[@"require.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ruby.xml" icon:@"ruby" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ruby_2.xml" icon:@"ruby" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ruby_on_Rails_3.xml" icon:@"rails" aliases:@"ror" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ruby_on_Rails_4.xml" icon:@"rails" aliases:@"ror" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Ruby_on_Rails_5.xml" icon:@"rails" aliases:@"ror" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"RubyMotion.xml" icon:@"rubymotion" aliases:nil doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Rust.xml" icon:@"rust" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SailsJS.xml" icon:@"sails" aliases:@[@"nodejs sails.js node.js sails.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SaltStack.xml" icon:@"salt" aliases:@[@"python", @"salt stack"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Sass.xml" icon:@"sass" aliases:@[@"ruby gems", @"rubygems"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Scala.xml" icon:@"scala" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SciPy.xml" icon:@"scipy" aliases:@[@"numpy", @"sci.py", @"num.py", @"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Semantic_UI.xml" icon:@"semantic" aliases:@[@"Semantic UI"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Sencha_Touch.xml" icon:@"sencha" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Sinon.xml" icon:@"sinon" aliases:@[@"sinonjs nodejs", @"sinon.js node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Smarty.xml" icon:@"smarty" aliases:@[@"Smarty Template Engine", @"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Sparrow.xml" icon:@"sparrow" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Spring_Framework.xml" icon:@"spring" aliases:@[@"spring.io", @"java"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SproutCore.xml" icon:@"SproutCore" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SQLAlchemy.xml" icon:@"sqlalchemy" aliases:@[@"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SQLite.xml" icon:@"sqlite" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Statamic.xml" icon:@"statamic" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Stylus.xml" icon:@"stylus" aliases:@[@"nodejs", @"node.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Susy.xml" icon:@"susy" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"SVG.xml" icon:@"svg" aliases:@[@"mdn", @"mozilla developer network"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Swift.xml" icon:@"swift" aliases:@[@"leopard", @"snow leopard", @"lion", @"mountain lion", @"mavericks", @"yosemite", @"10.10", @"10.8", @"10.6", @"mac osx", @"10.7", @"10.9", @"10.5", @"xcode", @"apple", @"cocoa", @"objective-c", @"objc", @"iphone", @"ipad", @"cocoa touch"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Symfony.xml" icon:@"symfony" aliases:@[@"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Tcl.xml" icon:@"tcl" aliases:@[@"tcl/tk", @"tcltk", @"tcl tk"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Tornado.xml" icon:@"tornado" aliases:@[@"python", @"tornado web server"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"tvOS.xml" icon:@"tvos" aliases:@[@"tvos", @"xcode", @"apple", @"cocoa", @"objective-c", @"objc", @"swift", @"tvservices", @"apple tv"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Twig.xml" icon:@"twig" aliases:@[@"Twig Template Engine", @"php"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Twisted.xml" icon:@"twisted" aliases:@[@"twisted matrix", @"python"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"TypeScript.xml" icon:@"typescript" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"TYPO3.xml" icon:@"typo3" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"UnderscoreJS.xml" icon:@"underscore" aliases:@[@"underscore.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Unity_3D.xml" icon:@"unity3d" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Vagrant.xml" icon:@"vagrant" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Vim.xml" icon:@"vim" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"VMware_vSphere.xml" icon:@"vsphere" aliases:nil doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"VueJS.xml" icon:@"vue" aliases:@[@"nodejs vue.js node.js vue.js"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"watchOS.xml" icon:@"watchos" aliases:@[@"iphoneos", @"ios", @"ipad", @"xcode", @"apple", @"cocoa touch", @"objective-c", @"objc", @"swift", @"watchkit"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"WordPress.xml" icon:@"wordpress" aliases:@[@"php"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Xamarin.xml" icon:@"xamarin" aliases:@[@"xamarin.ios", @"xamarin.mac", @"xamarin.android", @"xamarin.osx", @"xamarin ios", @"xamarin mac", @"xamarin android", @"xamarin osx", @"xamarin for ios", @"xamarin for mac", @"xamarin for android", @"xamarin for osx"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Xojo.xml" icon:@"xojo" aliases:@[@"realbasic", @"real basic", @"real studio", @"realstudio"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"XSLT.xml" icon:@"xslt" aliases:@[@"mdn", @"mozilla developer network", @"exslt", @"xpath"] doesNotHaveVersions:YES],
                           [DHFeed feedWithFeed:@"Yii.xml" icon:@"yii" aliases:@"yii framework yii2 framework php" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"YUI.xml" icon:@"yui" aliases:@"yui library" doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Zend_Framework_1.xml" icon:@"zend" aliases:@[@"zf1"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Zend_Framework_2.xml" icon:@"zend" aliases:@[@"zf2"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"Zend_Framework_3.xml" icon:@"zend" aliases:@[@"zf3"] doesNotHaveVersions:NO],
                           [DHFeed feedWithFeed:@"ZeptoJS.xml" icon:@"zepto" aliases:@[@"Zepto.js"] doesNotHaveVersions:NO],
                           nil];
    NSArray *savedFeeds = [[NSUserDefaults standardUserDefaults] objectForKey:[self defaultsKey]];
    for(NSDictionary *feedDictionary in savedFeeds)
    {
        DHFeed *savedFeed = [DHFeed feedWithDictionaryRepresentation:feedDictionary];
        if([@[@"http://kapeli.com/feeds/OS_X.xml", @"http://kapeli.com/feeds/watchOS.xml", @"http://kapeli.com/feeds/iOS.xml", @"http://kapeli.com/feeds/tvOS.xml", @"http://kapeli.com/feeds/Jade.xml", @"http://kapeli.com/feeds/JavaFX.xml", @"http://kapeli.com/feeds/Angular.dart.xml", @"http://kapeli.com/feeds/AngularTS.xml", @"http://kapeli.com/feeds/Gradle_Groovy_API.xml", @"http://kapeli.com/feeds/XUL.xml", @"http://kapeli.com/feeds/OpenCV_C.xml", @"http://kapeli.com/feeds/OpenCV_C++.xml", @"http://kapeli.com/feeds/OpenCV_Java.xml", @"http://kapeli.com/feeds/OpenCV_Python.xml"] containsObject:savedFeed.feedURL])
        {
            if(savedFeed.installed)
            {
                NSString *trashPath = [self uniqueTrashPath];
                NSString *feedPath = [self docsetPathForFeed:savedFeed];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [[DHDocsetManager sharedManager] removeDocsetsInFolder:feedPath];
                [fileManager moveItemAtPath:feedPath toPath:trashPath error:nil];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    [self emptyTrashAtPath:trashPath];
                });
            }
            savedFeed.installed = NO;
            savedFeed.installedVersion = nil;
        }
        if([@[@"http://kapeli.com/feeds/OS_X.xml", @"http://kapeli.com/feeds/Jade.xml", @"http://kapeli.com/feeds/JavaFX.xml", @"http://kapeli.com/feeds/Apple_Guides_and_Sample_Code.xml", @"http://kapeli.com/feeds/Angular.dart.xml", @"http://kapeli.com/feeds/AngularTS.xml", @"http://kapeli.com/feeds/Gradle_Groovy_API.xml", @"http://kapeli.com/feeds/XUL.xml", @"http://kapeli.com/feeds/OpenCV_C.xml", @"http://kapeli.com/feeds/OpenCV_C++.xml", @"http://kapeli.com/feeds/OpenCV_Java.xml", @"http://kapeli.com/feeds/OpenCV_Python.xml"] containsObject:savedFeed.feedURL])
        {
            continue;
        }
        NSUInteger index = [dashFeeds indexOfObjectPassingTest:^BOOL(DHFeed *obj, NSUInteger idx, BOOL *stop) {
            return [[obj feed] isEqualToString:savedFeed.feed];
        }];
        if(index != NSNotFound)
        {
            DHFeed *dashFeed = dashFeeds[index];
            dashFeed.installed = savedFeed.installed;
            dashFeed.installedVersion = savedFeed.installedVersion;
            dashFeed.size = savedFeed.size;
        }
        else
        {
            [dashFeeds addObject:savedFeed];
        }
    }
    [dashFeeds sortUsingFunction:compareFeeds context:nil];
    self.feeds = dashFeeds;
}

- (NSString *)installFeed:(DHFeed *)feed isAnUpdate:(BOOL)isAnUpdate
{
    NSObject *identifier = [[NSObject alloc] init];
    feed.identifier = identifier;
    feed.waiting = YES;
    BOOL didStallOnce = NO;
    BOOL didSetStallLabel = NO;
    while([self shouldStall] && feed.installing && feed.identifier == identifier)
    {
        if(didStallOnce && !didSetStallLabel)
        {
            didSetStallLabel = YES;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [feed setDetailString:@"Waiting..."];
                [[feed cell].titleLabel setRightDetailText:@"Waiting..." adjustMainWidth:YES];
                [feed setMaxRightDetailWidth:[feed cell].titleLabel.maxRightDetailWidth];
            });
        }
        didStallOnce = YES;
        [NSThread sleepForTimeInterval:1.0f];
    }
    if(!feed.installing || feed.identifier != identifier)
    {
        return @"cancelled";
    }
    feed.waiting = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *installPath = [self docsetPathForFeed:feed];
    NSString *tempPath = [self uniqueTempDirAtPath:installPath];
    NSString *tempFile = [tempPath stringByAppendingPathComponent:@"dash_temp_docset.tgz"];
    NSString *tarixFile = [tempFile stringByAppendingString:@".tarix"];
    
    __block BOOL shouldWait = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        shouldWait = [[DHLatencyTester sharedLatency] performTests:NO];
    });
    if(shouldWait)
    {
        [NSThread sleepForTimeInterval:3.0f];
    }
    if(!feed.installing || feed.identifier != identifier)
    {
        return @"cancelled";
    }
    NSString *error = nil;
    DHFeedResult *feedResult = [self loadFeed:feed error:&error];
    if(!feed.installing || feed.identifier != identifier)
    {
        return @"cancelled";
    }
    if(feedResult && feed.installing)
    {
        feed.feedResult = feedResult;
        feedResult.feed = feed;
        NSError *downloadError = nil;
        if(feedResult.downloadURLs.count)
        {
            NSString *downloadURL = feedResult.downloadURLs[0];
            [self emptyTrashAtPath:tempPath];
            if(![fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil])
            {
                return @"Couldn't create install directory.";
            }
            if([feedResult isCancelled])
            {
                [self emptyTrashAtPath:tempPath];
                return @"cancelled";
            }
            NSURL *url = [NSURL URLWithString:downloadURL];
            if(url)
            {
                BOOL result = NO;
                NSURL *tarixURL = [NSURL URLWithString:[[downloadURL stringByAppendingString:@".tarix"] stringByConvertingKapeliHttpURLToHttps]];
                feedResult.hasTarix = [NSURL URLIsFound:[tarixURL absoluteString] timeoutInterval:120.0f checkForRedirect:YES];
                downloadError = nil;
#ifdef DEBUG
                NSLog(@"Downloading %@", url);
#endif
                if([DHFileDownload downloadItemAtURL:url toFile:tempFile error:&downloadError delegate:self identifier:feedResult] && !downloadError)
                {
                    if([feedResult isCancelled])
                    {
                        [self emptyTrashAtPath:tempPath];
                        return @"cancelled";
                    }
                    
                    [feedResult setRightDetail:@"Waiting..."];
                    @synchronized([DHDocsetIndexer class])
                    {
                        if(!feedResult.hasTarix)
                        {
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            [fileManager removeItemAtPath:tarixFile error:nil];
                            result = [DHUnarchiver unarchiveArchive:tempFile delegate:feedResult];
                        }
                        else
                        {
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            [feedResult setRightDetail:@"Preparing..."];
                            result = [DHFileDownload downloadItemAtURL:tarixURL toFile:tarixFile error:nil delegate:nil identifier:nil];
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            if(!result)
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"Couldn't download index file.";
                            }
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            [feedResult setRightDetail:@"Extracting..."];
                            result = [DHUnarchiver unarchiveArchive:tarixFile delegate:nil];
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            if(!result)
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"Couldn't unarchive index file.";
                            }
                            [fileManager removeItemAtPath:tarixFile error:nil];
                            tarixFile = [fileManager firstFileWithExtension:@"tarix" atPath:tempPath ignoreHidden:YES];
                            if(!tarixFile)
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"Couldn't find index file.";
                            }
                            tarixFile = [tempPath stringByAppendingPathComponent:tarixFile];
                            result = [DHUnarchiver unpackTarixDocset:tempFile tarixPath:tarixFile delegate:feedResult];
                            if([feedResult isCancelled])
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"cancelled";
                            }
                            if(!result)
                            {
                                [self emptyTrashAtPath:tempPath];
                                return @"Couldn't unarchive docset.";
                            }
                        }
                        if([feedResult isCancelled])
                        {
                            [self emptyTrashAtPath:tempPath];
                            return @"cancelled";
                        }
                        
                        if(!result)
                        {
                            [self emptyTrashAtPath:tempPath];
                            return @"Couldn't unarchive docset.";
                        }
                        
                        if(!feedResult.hasTarix)
                        {
                            [fileManager removeItemAtPath:tempFile error:nil];
                        }
                        DHDocset *docset = [DHDocset firstDocsetInsideFolder:tempPath];
                        if(!docset)
                        {
                            [self emptyTrashAtPath:tempPath];
                            return @"Couldn't install docset.";
                        }
                        else if(feedResult.hasTarix)
                        {
                            [fileManager moveItemAtPath:tarixFile toPath:docset.tarixIndexPath error:nil];
                            [fileManager moveItemAtPath:tempFile toPath:docset.tarixPath error:nil];
                        }
                        [DHDocsetIndexer indexerForDocset:docset delegate:feedResult];
                        [fileManager removeItemAtPath:docset.sqlPath error:nil];
                        [fileManager removeItemAtPath:[docset.sqlPath stringByAppendingString:@"-shm"] error:nil];
                        [fileManager removeItemAtPath:[docset.sqlPath stringByAppendingString:@"-wal"] error:nil];
                        if([feedResult isCancelled])
                        {
                            [self emptyTrashAtPath:tempPath];
                            return @"cancelled";
                        }
                        
                        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:installPath];
                        NSString *file = nil;
                        while(file = [dirEnum nextObject])
                        {
                            [dirEnum skipDescendents];
                            NSString *filePath = [installPath stringByAppendingPathComponent:file];
                            if(![filePath isEqualToString:tempPath])
                            {
                                NSString *trashPath = [self uniqueTrashPath];
                                [fileManager moveItemAtPath:filePath toPath:trashPath error:nil];
                                dispatch_queue_t queue = dispatch_queue_create([[NSString stringWithFormat:@"%u", arc4random() % 100000] UTF8String], 0);
                                dispatch_async(queue, ^{
                                    [self emptyTrashAtPath:trashPath];
                                });
                            }
                        }
                        [fileManager moveItemAtPath:docset.path toPath:[installPath stringByAppendingPathComponent:[docset.path lastPathComponent]] error:nil];
                        [self emptyTrashAtPath:tempPath];
                        return nil;
                    }
                }
                else if(downloadError.code == DHDownloadCancelled)
                {
                    [self emptyTrashAtPath:tempPath];
                    return @"cancelled";
                }
                else
                {
                    [self emptyTrashAtPath:tempPath];
                }
            }
        }
        return @"Couldn't download docset.";
    }
    else
    {
        return error;
    }
    return nil;
}

// This does not modify the feed at all
- (DHFeedResult *)loadFeed:(DHFeed *)feed error:(NSString **)returnError
{
    @try
    {
        __block NSError *error = nil;
        NSString *originalFeedURL = feed.feedURL;
        NSString *lastPathComponent = [originalFeedURL lastPathComponent];
        BOOL isDash = !feed.isCustom;
        if(originalFeedURL)
        {
            NSMutableArray *feedURLs = [NSMutableArray arrayWithObject:originalFeedURL];
            if(isDash)
            {
                NSString *cdnFeedURL = [originalFeedURL substringFromStringReturningNil:@"/feeds/"];
                cdnFeedURL = (cdnFeedURL) ? [[[DHLatencyTester sharedLatency] bestMirror] stringByAppendingString:cdnFeedURL] : nil;
                cdnFeedURL = [cdnFeedURL stringByConvertingKapeliHttpURLToHttps];
                if(cdnFeedURL)
                {
                    feedURLs = [NSMutableArray arrayWithObject:cdnFeedURL];
                    NSString *secondBest = [[[DHLatencyTester sharedLatency] secondBestMirror] stringByAppendingString:[originalFeedURL substringFromStringReturningNil:@"/feeds/"]];
                    secondBest = [secondBest stringByConvertingKapeliHttpURLToHttps];
                    [feedURLs addObject:secondBest];
                }
                else
                {
                    [feedURLs addObject:[@"https://kapeli.com/feeds/" stringByAppendingString:lastPathComponent]];
                }
            }
            NSCondition *condition = [[NSCondition alloc] init];
            NSMutableArray *xmls = [NSMutableArray array];
            NSLock *workerLock = [[NSLock alloc] init];
            __block BOOL succeeded = NO;
            __block NSInteger workerCount = feedURLs.count;
            for(NSString *feedURL in feedURLs)
            {
                dispatch_queue_t myQueue = dispatch_queue_create([feedURL UTF8String], 0);
                dispatch_async(myQueue, ^{
                    NSURL *xmlURL = [NSURL URLWithString:feedURL];
                    BOOL didSucceed = NO;
                    NSError *workingError = nil;
                    if(xmlURL)
                    {
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:xmlURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:90.0f];
                        [request setValue:[[NSBundle mainBundle] bundleIdentifier] forHTTPHeaderField:@"User-Agent"];
                        NSURLResponse *response = nil;
                        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&workingError];
                        if(data && !workingError)
                        {
                            NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            if(xmlString && xmlString.length)
                            {
                                NSXMLDocument *xml = [[NSXMLDocument alloc] initWithXMLString:xmlString options:0 error:&workingError];
                                NSXMLElement *root = [xml rootElement];
                                if([[root name] isCaseInsensitiveEqual:@"feed"])
                                {
                                    root = [[root elementsForName:@"entry"] count] > 0 ? [root elementsForName:@"entry"][0] : nil;
                                }
                                if(xml && root && ([root elementsForName:@"version"].count || [root elementsForName:@"docset:version"].count) && ([root elementsForName:@"url"].count || [root elementsForName:@"link"].count))
                                {
                                    [xmls addObject:xml];
                                    [condition lock];
                                    [condition signal];
                                    [condition unlock];
                                    didSucceed = YES;
                                }
                            }
                        }
                    }
                    [workerLock lock];
                    if(didSucceed)
                    {
                        succeeded = YES;
                    }
                    BOOL otherSucceeded = succeeded;
                    --workerCount;
                    BOOL isLast = workerCount == 0;
                    [workerLock unlock];
                    if(isLast && !didSucceed && !otherSucceeded)
                    {
                        error = workingError;
                        [condition lock];
                        [condition signal];
                        [condition unlock];
                    }
                });
            }
            [condition lock];
            [condition wait];
            [condition unlock];
            
            NSXMLDocument *xml = nil;
            if(xmls.count)
            {
                xml = xmls[0];
            }
            if(!xml)
            {
                if([error localizedDescription])
                {
                    *returnError = @"Unable to load docset feed.";
                }
                return nil;
            }
            else
            {
                NSXMLElement *root = [xml rootElement];
                BOOL isXcode = NO;
                if([[root name] isCaseInsensitiveEqual:@"feed"])
                {
                    root = [[root elementsForName:@"entry"] count] > 0 ? [root elementsForName:@"entry"][0] : nil;
                    isXcode = YES;
                }
                if(root)
                {
                    if([[root name] isCaseInsensitiveEqual:@"entry"])
                    {
                        NSArray *versions = [root elementsForName:(!isXcode) ? @"version" : @"docset:version"];
                        NSString *iosVersion = [[[root elementsForName:@"ios_version"] firstObject] stringValue];
                        if(versions.count == 1)
                        {
                            if([versions[0] stringValue].length)
                            {
                                DHFeedResult *result = [[DHFeedResult alloc] init];
                                NSString *version = [versions[0] stringValue];
                                if(iosVersion && iosVersion.length)
                                {
                                    version = [version stringByAppendingFormat:@"/%@", iosVersion];
                                }
                                result.version = version;
                                NSArray *docsetURLs = [root elementsForName:(!isXcode) ? @"url" : @"link"];
                                NSMutableArray *urlResults = [NSMutableArray array];
                                for(NSXMLElement *docsetURL in docsetURLs)
                                {
                                    NSString *urlString = (!isXcode) ? [docsetURL stringValue] : [[docsetURL attributeForName:@"href"] stringValue];
                                    if(urlString.length)
                                    {
                                        [urlResults addObject:[urlString trimWhitespace]];
                                    }
                                }
                                if(isDash)
                                {
                                    [[DHLatencyTester sharedLatency] sortURLsBasedOnLatency:urlResults];
                                }
                                if(urlResults.count)
                                {
                                    if(isXcode && [root elementsForName:@"title"].count)
                                    {
                                        NSString *xcodeName = [[root elementsForName:@"title"][0] stringValue];
                                        if(xcodeName && xcodeName.length)
                                        {
//                                            [feed setObject:xcodeName forKey:@"xcodeName"];
                                        }
                                    }
                                    result.downloadURLs = urlResults;
                                    return result;
                                }
                                else
                                {
                                    *returnError = @"Unable to load docset feed.";
                                }
                            }
                        }
                    }
                }
                *returnError = @"Unable to parse docset feed.";
                return nil;
            }
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"FIXME: exception in loadFeed: %@", exception);
        NSLog(@"%@", [NSThread callStackSymbols]);
    }
    return nil;
}

- (NSString *)docsetInstallFolderName
{
    return @"Dash";
}

- (BOOL)canInstallFeed:(DHFeed *)feed
{
    NSString *title = nil;
    NSString *message = nil;
    if([feed.feedURL isEqualToString:@"http://kapeli.com/feeds/DOM.xml"])
    {
        title = @"DOM Documentation";
        message = @"There is no DOM docset. DOM documentation can be found in the JavaScript docset. Please install the JavaScript docset instead.";
    }
    else if([feed.feedURL isEqualToString:@"http://kapeli.com/feeds/RubyMotion.xml"])
    {
        title = @"RubyMotion Documentation";
        message = @"RubyMotion had to remove its API documentation due to legal reasons. Please contact the RubyMotion team for more details.\n\nIn the meantime, you can use the Apple API Reference docset instead.";
    }
    else if([feed.feedURL isEqualToString:@"http://kapeli.com/feeds/Apple_API_Reference.xml"])
    {
        title = @"Apple API Reference";
        message = @"To install the Apple API Reference docset you need to:\n\n1. Use Dash for macOS to install the Apple API Reference docset from Preferences > Downloads\n2. Go to Preferences > Docsets, right click the Apple API Reference docset and select \"Generate iOS Compatible Docset\"\n3. Transfer the resulting docset using iTunes File Sharing or AirDrop";
    }
    else if([@[@"http://kapeli.com/feeds/OS_X.xml", @"http://kapeli.com/feeds/macOS.xml", @"http://kapeli.com/feeds/watchOS.xml", @"http://kapeli.com/feeds/iOS.xml", @"http://kapeli.com/feeds/tvOS.xml"] containsObject:feed.feedURL])
    {
        title = @"Apple API Reference";
        NSString *name = [[[feed.feedURL lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        message = [NSString stringWithFormat:@"There is no %@ docset. The documentation for %@ can be found inside the Apple API Reference docset. \n\nTo install the Apple API Reference docset you need to:\n\n1. Use Dash for macOS to install the docset from Preferences > Downloads\n2. Go to Preferences > Docsets, right click the Apple API Reference docset and select \"Generate iOS-compatible Docset\"\n3. Transfer the resulting docset using iTunes File Sharing or AirDrop", name, name];
    }
    
    if(title && message)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

+ (instancetype)sharedDownloader
{
    if(singleton)
    {
        return singleton;
    }
    id downloader = [[DHAppDelegate mainStoryboard] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    [downloader setUp];
    return downloader;
}

+ (id)alloc
{
    if(singleton)
    {
        return singleton;
    }
    return [super alloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(singleton)
    {
        return singleton;
    }
    self = [super initWithCoder:aDecoder];
    singleton = self;
    return self;
}

@end
