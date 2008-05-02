hurl
    by Mike Mondragon
    mikemondragon@gmail.com
    http://blog.mondragon.cc/

== DESCRIPTION:
  
A Camping implementation of Tiny URL, but even more tiny.  If you drink 
too much while camping this is what happens, but even smaller.  What you 
can do with an idea borne in PHP, but with less code using Ruby and 
metaprogramming.

== FEATURES/PROBLEMS:
  
Enter URL, get back an even smaller URL.

== REQUIREMENTS:

* camping
* mime-types
* erubis
* sqlite3-ruby
* mysql
* alphadecimal http://github.com/JackDanger/Alphadecimal
* deployment in RV
  http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping/

== INSTALL:

* git clone git@github.com:monde/hurl.git
* modify template erb's in templates directory to suit your desires
* modify urchin.txt in templates directory for Google Analytics support

== Administrative

The admin directory contains an example RV harness yaml configuration file, 
see "rv, a tool for luxurious camping" by Evan Weaver for more information:
http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping

When running in testing mode Hurl will use a local SQLite3 database.  When
running in productiton mode Hurl will use a MySQL database.  See the 
db migration to examine how the db is tuned based on the running mode.

See http://camping.rubyforge.org/files/README.html for more information about
Camping applications.

Original blog post announcing (deprecated HURL)
http://blog.mondragon.cc/articles/2007/07/04/small-urls-with-camping
http://blog.mondragon.cc/articles/2007/07/05/rv2-camping-on-gentoo

== Running

In testing mode:
rake hurl
or
camping hurl.rb

In production mode:
see rv notes

== Test

rake test
or
autotest


== LICENSE:

rv_harness.rb are AFL licensed works derived from Evan Weaver.
Everything else is MIT

(The MIT License)

Copyright (c) 2007, 2008 Mike Mondragon (mikemondragon@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
