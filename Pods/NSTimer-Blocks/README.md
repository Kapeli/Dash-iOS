README
======

Extremely simple category on NSTimer which makes it able to use blocks.

HOW IT WORKS
------------

I figure if you're using a block, you probably won't need to pass any userinfo object into the timer... you can get to whatever you need just from the block.  So, I just hijack the `+scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:` class method and it's brother `-init...`, setting it to use itself as the target, and to execute the class method `+jdExecuteSimpleBlock:` (which is part of the category) then pass the block you specify as the userInfo object which is then uses in the execute method.  Pretty straightforward stuff.

HOW TO USE IT
-------------

Very simple:

	[NSTimer scheduledTimerWithTimeInterval:2.0 block:^
	{
		[someObj doSomething];
		[someOtherObj doSomethingElse];
		// ... etc ...
	} repeats:NO];
	
This may be overkill for most NSTimer operations... I mean, do you really have a need for a block?  Couldn't you use the selector methods?  Sure you could... but sometimes it's more elegant to use a block... so here you go.


LICENSE
-------

Copyright (C) 2011 by Random Ideas, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.