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
  
Enter URL, get back even smaller URL.

== REQUIREMENTS:

* camping
* mime-types
* erubis
* builder
* sqlite3-ruby
* mysql

== INSTALL:

* gem install hurl

The Hurl will a prepopulate 3906 keys (62^1 + 62^2) when it itializes
its database with a migration in production mode.

== Administrative

Use the make_keys.rb script to make additional prepopulated keys.  For 
instance make 238328 unique keys:
ruby admin/make_keys.rb 3 > /tmp/hurl_keys-3.sql

Make another 14776336 unique keys:
ruby admin/make_keys.rb 4 > /tmp/hurl_keys-4.sql

Then load those keys your db, the example db is named hurl:
mysql -u root -p hurl < /tmp/hurl_keys-3.sql
mysql -u root -p hurl < /tmp/hurl_keys-4.sql
note: 62^4 keys takes up about 750MB disk space with the MyISAM engine.

Also in the admin directory is an example RV harness, see "rv, a tool for 
luxurious camping" by Evan Weaver for more information:
http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping

There is also an alternative harness called RV2 in the admin direcotry
that is SysV init.d shell based.  For its use see:

http://blog.mondragon.cc/articles/2007/07/04/small-urls-with-camping
http://blog.mondragon.cc/articles/2007/07/05/rv2-camping-on-gentoo

When running in testing mode Hurl will use a local SQLite3 database.  When
running in produciton mode Hurl will use a MySQL database.  See the 
db migration to examine how the db is tuned based on the running mode.

See http://camping.rubyforge.org/files/README.html for more information about
Camping applications.

== Running

In testing mode:
rake hurl
or
camping hurl.rb

In production mode:
see rv and RV2 notes

== Test

rake test
or
autotest


== LICENSE:

rv_harness.rb and rv_harness2.rb are AFL licensed works dervived from
Evan Weaver.  Everything else is MIT

(The MIT License)

Copyright (c) 2007 FIX

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
