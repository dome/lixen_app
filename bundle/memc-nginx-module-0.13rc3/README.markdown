Name
====

**memc-nginx-module** - An extended version of the standard memcached module that supports set, add, delete, and many more memcached commands.

*This module is not distributed with the Nginx source.* See [the installation instructions](http://wiki.nginx.org/HttpMemcModule#Installation).

Version
=======

This document describes memc-nginx-module [v0.13rc2](http://github.com/agentzh/memc-nginx-module/tags) released on 24 November 2011.

Synopsis
========


    # GET /foo?key=dog
    #
    # POST /foo?key=cat
    # Cat's value...
    #
    # PUT /foo?key=bird
    # Bird's value...
    #
    # DELETE /foo?key=Tiger
    location /foo {
        set $memc_key $arg_key;

        # $memc_cmd defaults to get for GET,
        #   add for POST, set for PUT, and
        #   delete for the DELETE request method.

        memc_pass 127.0.0.1:11211;
    }



    # GET /bar?cmd=get&key=cat
    #
    # POST /bar?cmd=set&key=dog
    # My value for the "dog" key...
    #
    # DELETE /bar?cmd=delete&key=dog
    # GET /bar?cmd=delete&key=dog
    location /bar {
        set $memc_cmd $arg_cmd;
        set $memc_key $arg_key;
        set $memc_flags $arg_flags; # defaults to 0
        set $memc_exptime $arg_exptime; # defaults to 0

        memc_pass 127.0.0.1:11211;
    }



    # GET /bar?cmd=get&key=cat
    # GET /bar?cmd=set&key=dog&val=animal&flags=1234&exptime=2
    # GET /bar?cmd=delete&key=dog
    # GET /bar?cmd=flush_all
    location /bar {
        set $memc_cmd $arg_cmd;
        set $memc_key $arg_key;
        set $memc_value $arg_val;
        set $memc_flags $arg_flags; # defaults to 0
        set $memc_exptime $arg_exptime; # defaults to 0

        memc_cmds_allowed get set add delete flush_all;

        memc_pass 127.0.0.1:11211;
    }



      http {
        ...
        upstream backend {
           server 127.0.0.1:11984;
           server 127.0.0.1:11985;
        }
        server {
            location /stats {
                set $memc_cmd stats;
                memc_pass backend;
            }
            ...
        }
      }
      ...



    # read the memcached flags into the Last-Modified header
    # to respond 304 to conditional GET
    location /memc {
        set $memc_key $arg_key;

        memc_pass 127.0.0.1:11984;

        memc_flags_to_last_modified on;
    }



    location /memc {
        set $memc_key foo;
        set $memc_cmd get;

        # access the unix domain socket listend by memcached
        memc_pass unix:/tmp/memcached.sock;
    }


Description
===========

This module extends the standard [memcached module](http://wiki.nginx.org/HttpMemcachedModule) to support almost the whole [memcached ascii protocol](http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt).

It allows you to define a custom [REST](http://en.wikipedia.org/wiki/REST) interface to your memcached servers or access memcached in a very efficient way from within the nginx server by means of subrequests or [independent fake requests](http://github.com/srlindsay/nginx-independent-subrequest).

This module is not supposed to be merged into the Nginx core because I've used [Ragel](http://www.complang.org/ragel/) to generate the memcached response parsers (in C) for joy :)

If you are going to use this module to cache location responses out of the box, try [HttpSRCacheModule](http://wiki.nginx.org/HttpSRCacheModule) with this module to achieve that.

Keep-alive connections to memcached servers
-------------------------------------------

You need [HttpUpstreamKeepaliveModule](http://wiki.nginx.org/HttpUpstreamKeepaliveModule) together with this module for keep-alive TCP connections to your backend memcached servers.

Here's a sample configuration:


      http {
        upstream backend {
          server 127.0.0.1:11211;
    
          # a pool with at most 1024 connections
          # and do not distinguish the servers:
          keepalive 1024 single;
        }
    
        server {
            ...
            location /memc {
                set $memc_cmd get;
                set $memc_key $arg_key;
                memc_pass backend;
            }
        }
      }


How it works
------------

It implements the memcached TCP protocol all by itself, based upon the `upstream` mechansim. Everything involving I/O is non-blocking.

The module itself does not keep TCP connections to the upstream memcached servers across requests, just like other upstream modules. For a working solution, see section [Keep-alive connections to memcached servers](http://wiki.nginx.org/HttpMemcModule#Keep-alive_connections_to_memcached_servers).

Memcached commands supported
============================

The memcached storage commands [set](http://wiki.nginx.org/HttpMemcModule#set_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value), [add](http://wiki.nginx.org/HttpMemcModule#add_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value), [replace](http://wiki.nginx.org/HttpMemcModule#replace_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value), [prepend](http://wiki.nginx.org/HttpMemcModule#prepend_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value), and [append](http://wiki.nginx.org/HttpMemcModule#append_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value) uses the `$memc_key` as the key, `$memc_exptime` as the expiration time (or delay) (defaults to 0), `$memc_flags` as the flags (defaults to 0), to build the corresponding memcached queries.

If `$memc_value` is not defined at all, then the request body will be used as the value of the `$memc_value` except for the [incr](http://wiki.nginx.org/HttpMemcModule#incr_.24memc_key_.24memc_value) and [decr](http://wiki.nginx.org/HttpMemcModule#decr_.24memc_key_.24memc_value) commands. Note that if `$memc_value` is defined as an empty string (`""`), that empty string will still be used as the value as is.

The following memcached commands have been implemented and tested (with their parameters marked by corresponding
nginx variables defined by this module):

get $memc_key
-------------

Retrieves the value using a key.


      location /foo {
          set $memc_cmd 'get';
          set $memc_key 'my_key';
          
          memc_pass 127.0.0.1:11211;
          
          add_header X-Memc-Flags $memc_flags;
      }


Returns `200 OK` with the value put into the response body if the key is found, or `404 Not Found` otherwise. The `flags` number will be set into the `$memc_flags` variable so it's often desired to put that info into the response headers by means of the standard [add_header directive](http://wiki.nginx.org/HttpHeadersModule#add_header).

It returns `502` for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

set $memc_key $memc_flags $memc_exptime $memc_value
---------------------------------------------------

To use the request body as the memcached value, just avoid setting the `$memc_value` variable:


      # POST /foo
      # my value...
      location /foo {
          set $memc_cmd 'set';
          set $memc_key 'my_key';
          set $memc_flags 12345;
          set $memc_exptime 24;
          
          memc_pass 127.0.0.1:11211;
      }


Or let the `$memc_value` hold the value:


      location /foo {
          set $memc_cmd 'set';
          set $memc_key 'my_key';
          set $memc_flags 12345;
          set $memc_exptime 24;
          set $memc_value 'my_value';
    
          memc_pass 127.0.0.1:11211;
      }


Returns `201 Created` if the upstream memcached server replies `STORED`, `200` for `NOT_STORED`, `404` for `NOT_FOUND`, `502` for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

The original memcached responses are returned as the response body except for `404 NOT FOUND`.

add $memc_key $memc_flags $memc_exptime $memc_value
---------------------------------------------------

Similar to the [set command](http://wiki.nginx.org/HttpMemcModule#set_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value).

replace $memc_key $memc_flags $memc_exptime $memc_value
-------------------------------------------------------

Similar to the [set command](http://wiki.nginx.org/HttpMemcModule#set_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value).

append $memc_key $memc_flags $memc_exptime $memc_value
------------------------------------------------------

Similar to the [set command](http://wiki.nginx.org/HttpMemcModule#set_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value).

Note that at least memcached version 1.2.2 does not support the "append" and "prepend" commands. At least 1.2.4 and later versions seem to supports these two commands.

prepend $memc_key $memc_flags $memc_exptime $memc_value
-------------------------------------------------------

Similar to the [append command](http://wiki.nginx.org/HttpMemcModule#append_.24memc_key_.24memc_flags_.24memc_exptime_.24memc_value).

delete $memc_key
----------------

Deletes the memcached entry using a key.


      location /foo
          set $memc_cmd delete;
          set $memc_key my_key;
          
          memc_pass 127.0.0.1:11211;
      }


Returns `200 OK` if deleted successfully, `404 Not Found` for `NOT_FOUND`, or `502` for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

The original memcached responses are returned as the response body except for `404 NOT FOUND`.

delete $memc_key $memc_exptime
------------------------------

Similar to the [delete $memc_key](http://wiki.nginx.org/HttpMemcModule#delete_.24memc_key) command except it accepts an optional `expiration` time specified by the `$memc_exptime` variable.

This command is no longer available in the latest memcached version 1.4.4.

incr $memc_key $memc_value
--------------------------

Increments the existing value of `$memc_key` by the amount specified by `$memc_value`:


      location /foo {
          set $memc_key my_key;
          set $memc_value 2;
          memc_pass 127.0.0.1:11211;
      }


In the preceding example, every time we access `/foo` will cause the value of `my_key` increments by `2`.

Returns `200 OK` with the new value associated with that key as the response body if successful, or `404 Not Found` if the key is not found.

It returns `502` for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

decr $memc_key $memc_value
--------------------------

Similar to [incr $memc_key $memc_value](http://wiki.nginx.org/HttpMemcModule#incr_.24memc_key_.24memc_value).

flush_all
---------

Mark all the keys on the memcached server as expired:


      location /foo {
          set $memc_cmd flush_all;
          memc_pass 127.0.0.1:11211;
      }


flush_all $memc_exptime
-----------------------

Just like [flush_all](http://wiki.nginx.org/HttpMemcModule#flush_all) but also accepts an expiration time specified by the `$memc_exptime` variable.

stats
-----

Causes the memcached server to output general-purpose statistics and settings


      location /foo {
          set $memc_cmd stats;
          memc_pass 127.0.0.1:11211;
      }


Returns `200 OK` if the request succeeds, or 502 for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

The raw `stats` command output from the upstream memcached server will be put into the response body. 

version
-------

Queries the memcached server's version number:


      location /foo {
          set $memc_cmd version;
          memc_pass 127.0.0.1:11211;
      }


Returns `200 OK` if the request succeeds, or 502 for `ERROR`, `CLIENT_ERROR`, or `SERVER_ERROR`.

The raw `version` command output from the upstream memcached server will be put into the response body.

Directives
==========

All the standard [memcached module](http://wiki.nginx.org/HttpMemcachedModule) directives in nginx 0.8.28 are directly inherited, with the `memcached_` prefixes replaced by `memc_`. For example, the `memcached_pass` directive is spelled `memc_pass`.

Here we only document the most important two directives (the latter is a new directive introduced by this module).

memc_pass
---------

**syntax:** *memc_pass &lt;memcached server IP address&gt;:&lt;memcached server port&gt;*

**syntax:** *memc_pass &lt;memcached server hostname&gt;:&lt;memcached server port&gt;*

**syntax:** *memc_pass &lt;upstream_backend_name&gt;*

**syntax:** *memc_pass unix:&lt;path_to_unix_domain_socket&gt;*

**default:** *none*

**context:** *http, server, location, if*

**phase:** *content*

Specify the memcached server backend.

memc_cmds_allowed
-----------------
**syntax:** *memc_cmds_allowed &lt;cmd&gt;...*

**default:** *none*

**context:** *http, server, location, if*

Lists memcached commands that are allowed to access. By default, all the memcached commands supported by this module are accessible.
An example is


       location /foo {
           set $memc_cmd $arg_cmd;
           set $memc_key $arg_key;
           set $memc_value $arg_val;
           
           memc_pass 127.0.0.1:11211;
            
           memc_cmds_allowed get;
       }


memc_flags_to_last_modified
---------------------------
**syntax:** *memc_flags_to_last_modified on|off*

**default:** *off*

**context:** *http, server, location, if*

Read the memcached flags as epoch seconds and set it as the value of the `Last-Modified` header. For conditional GET, it will signal nginx to return `304 Not Modified` response to save bandwidth.

memc_connect_timeout
--------------------
**syntax:** *memc_connect_timeout &lt;time&gt;*

**default:** *60s*

**context:** *http, server, location*

The timeout for connecting to the memcached server, in seconds by default.

It's wise to always explicitly specify the time unit to avoid confusion. Time units supported are "s"(seconds), "ms"(milliseconds), "y"(years), "M"(months), "w"(weeks), "d"(days), "h"(hours), and "m"(minutes).

This time must be less than 597 hours.

memc_send_timeout
-----------------
**syntax:** *memc_send_timeout &lt;time&gt;*

**default:** *60s*

**context:** *http, server, location*

The timeout for sending TCP requests to the memcached server, in seconds by default.

It's wise to always explicitly specify the time unit to avoid confusion. Time units supported are "s"(seconds), "ms"(milliseconds), "y"(years), "M"(months), "w"(weeks), "d"(days), "h"(hours), and "m"(minutes).

This time must be less than 597 hours.

memc_read_timeout
-----------------
**syntax:** *memc_read_timeout &lt;time&gt;*

**default:** *60s*

**context:** *http, server, location*

The timeout for reading TCP responses from the memcached server, in seconds by default.

It's wise to always explicitly specify the time unit to avoid confusion. Time units supported are "s"(seconds), "ms"(milliseconds), "y"(years), "M"(months), "w"(weeks), "d"(days), "h"(hours), and "m"(minutes).

This time must be less than 597 hours.

memc_buffer_size
----------------
**syntax:** *memc_buffer_size &lt;size&gt;*

**default:** *4k/8k*

**context:** *http, server, location*

This buffer size is used for the memory buffer to hold

* the complete response for memcached commands other than `get`,
* the complete response header (i.e., the first line of the response) for the `get` memcached command.

This default size is the page size, may be `4k` or `8k`.

Installation
============

You're recommended to install this module (as well as the Nginx core and many other goodies) via the [ngx_openresty bundle](http://openresty.org). See the [installation steps](http://openresty.org/#Installation) for `ngx_openresty`.

Alternatively, you can compile this module into the standard Nginx source distribution by hand:

Grab the nginx source code from [nginx.org](http://nginx.org/), for example,
the version 1.0.8 (see [nginx compatibility](http://wiki.nginx.org/HttpMemcModule#Compatibility)), and then build the source with this module:


    wget 'http://nginx.org/download/nginx-1.0.8.tar.gz'
    tar -xzvf nginx-1.0.8.tar.gz
    cd nginx-1.0.8/
    
    # Here we assume you would install you nginx under /opt/nginx/.
    ./configure --prefix=/opt/nginx \
        --add-module=/path/to/memc-nginx-module
     
    make -j2
    make install


Download the latest version of the release tarball of this module from [memc-nginx-module file list](http://github.com/agentzh/memc-nginx-module/tags).

For Developers
--------------

The memached response parsers were generated by [Ragel](http://www.complang.org/ragel/). If you want to
regenerate the parser's C file, i.e., [src/ngx_http_memc_response.c](http://github.com/agentzh/memc-nginx-module/blob/master/src/ngx_http_memc_response.c), use the following command from the root of the memc module's source tree:


    $ ragel -G2 src/ngx_http_memc_response.rl


Compatibility
=============

The following versions of Nginx should work with this module:

* **1.1.x**                       (last tested: 1.1.5)
* **1.0.x**                       (last tested: 1.0.10)
* **0.9.x**                       (last tested: 0.9.4)
* **0.8.x**                       (last tested: 0.8.54)
* **0.7.x >= 0.7.46**             (last tested: 0.7.68)

It's worth mentioning that some 0.7.x versions older than 0.7.46 might also work, but I can't easily test them because the test suite makes extensive use of the [echo module](http://wiki.nginx.org/HttpEchoModule)'s [echo_location directive](http://wiki.nginx.org/HttpEchoModule#echo_location), which requires at least nginx 0.7.46 :)

Earlier versions of Nginx like 0.6.x and 0.5.x will *not* work.

If you find that any particular version of Nginx above 0.7.46 does not work with this module, please consider [reporting a bug](http://wiki.nginx.org/HttpMemcModule#Report_Bugs).

Report Bugs
===========

Although a lot of effort has been put into testing and code tuning, there must be some serious bugs lurking somewhere in this module. So whenever you are bitten by any quirks, please don't hesitate to

1. create a ticket on the [issue tracking interface](http://github.com/agentzh/memc-nginx-module/issues) provided by GitHub,
1. or send a bug report or even patches to the [nginx mailing list](http://mailman.nginx.org/mailman/listinfo/nginx).

Source Repository
=================

Available on github at [agentzh/memc-nginx-module](http://github.com/agentzh/memc-nginx-module).

ChangeLog
=========

v0.12
-----
* fixed the spots that trigger the unused-but-set-variable warning by gcc 4.6.
* added more debug information when memcached sends back "invalid" responses.
* we now document the timeout units properly. it should default to seconds.
* now we use the 2-clause bsd license.
* added an error message when no upstream backend is found in "memc_pass $backend".

v0.11
-----
* fixed the zero size buf alert in error.log when $memc_value is set to empty (""). thanks iframist.

v0.10
-----
* we no longer use the problematic `ngx_strXcmp` macros in our source because it may cause invalid reads and thus segmentation faults. thanks Piotr Sikora.

v0.09
-----
* now we copy out `r->request_body->bufs` for our memcached request to avoid modifying the original request body. Thanks Matthieu Tourne.

v0.08
-----
* now the memc commands other than get work with subrequests in memory. Thanks Yao Xinming for reporting it. Using storage memcached commands in ngx_eval module's eval blocks no longer hang the server.

v0.07
-----
* applied the patch from nginx 0.8.35 that fixed a bug that ngx_eval may issue the incorrect error message "memcached sent invalid trailer".

v0.06
-----
* implemented the [memc_flags_to_last_modified](http://wiki.nginx.org/HttpMemcModule#memc_flags_to_last_modified) directive.
* added a new variable named [$memc_flags_as_http_time](http://wiki.nginx.org/HttpMemcModule#.24memc_flags_as_http_time).

v0.05
-----
* removed the `memc_bind` directive since it won't compile with nginx 0.8.31.

v0.04
-----
* to ensure Maxim's [ngx_http_upstream_keepalive](http://mdounin.ru/hg/ngx_http_upstream_keepalive/) module caches our connections even if `u->headers_in->status` is 201 (Created).
* updated docs to make it clear that this module can work with "upstream" multi-server backends. thanks Bernd Dorn for reporting it.

v0.03
-----
* fixed a connection leak caused by an extra `r->main->count++` operation: we should NOT do `r->main->count++` after calling the `ngx_http_read_client_request_body` function in our content handler.

v0.02
-----
* applied the (minor) optimization trick suggested by Marcus Clyne: creating our variables and save their indexes at post-config phase when the [memc_pass](http://wiki.nginx.org/HttpMemcModule#memc_pass) directive is actually used in the config file.

v0.01
-----
* initial release.

Test Suite
==========

This module comes with a Perl-driven test suite. The [test cases](http://github.com/agentzh/memc-nginx-module/tree/master/t/) are
[declarative](http://github.com/agentzh/memc-nginx-module/blob/master/t/storage.t) too. Thanks to the [Test::Base](http://search.cpan.org/perldoc?Test::Base) module in the Perl world.

To run it on your side:


    $ PATH=/path/to/your/nginx-with-memc-module:$PATH prove -r t


You need to terminate any Nginx processes before running the test suite if you have changed the Nginx server binary.

Either [LWP::UserAgent](http://search.cpan.org/perldoc?LWP::UserAgent) or [IO::Socket](http://search.cpan.org/perldoc?IO::Socket) is used by the [test scaffold](http://github.com/agentzh/memc-nginx-module/blob/master/test/lib/Test/Nginx/LWP.pm).

Because a single nginx server (by default, `localhost:1984`) is used across all the test scripts (`.t` files), it's meaningless to run the test suite in parallel by specifying `-jN` when invoking the `prove` utility.

You should also keep a memcached server listening on the `11211` port at localhost before running the test suite.

Some parts of the test suite requires modules [rewrite](http://wiki.nginx.org/HttpRewriteModule) and [echo](http://wiki.nginx.org/HttpEchoModule) to be enabled as well when building Nginx.

TODO
====

* add support for the memcached commands `cas`, `gets` and `stats $memc_value`.
* add support for the `noreply` option.

Getting involved
================

You'll be very welcomed to submit patches to the [author](http://wiki.nginx.org/HttpMemcModule#Author) or just ask for a commit bit to the [source repository](http://wiki.nginx.org/HttpMemcModule#Source_Repository) on GitHub.

Author
======

agentzh (章亦春) *&lt;agentzh@gmail.com&gt;*

This wiki page is also maintained by the author himself, and everybody is encouraged to improve this page as well.

Copyright & License
===================

The code base is borrowed directly from the standard [memcached module](http://wiki.nginx.org/HttpMemcachedModule) in the Nginx 0.8.28 core. This part of code is copyrighted by Igor Sysoev.

Copyright (c) 2009, 2010, 2011, Zhang "agentzh" Yichun (章亦春) <agentzh@gmail.com>.

This module is licensed under the terms of the BSD license.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========

* The original announcement email on the nginx mailing list: [ngx_memc: "an extended version of ngx_memcached that supports set, add, delete, and many more commands"](http://forum.nginx.org/read.php?2,28359)
* My slides demonstrating various ngx_memc usage: <http://agentzh.org/misc/slides/nginx-conf-scripting/nginx-conf-scripting.html#34> (use the arrow or pageup/pagedown keys on the keyboard to swith pages)
* The latest [memcached TCP protocol](http://code.sixapart.com/svn/memcached/trunk/server/doc/protocol.txt).
* The [ngx_srcache](http://github.com/agentzh/srcache-nginx-module) module
* The standard [memcached](http://wiki.nginx.org/HttpMemcachedModule) module.
* The [echo module](http://wiki.nginx.org/HttpEchoModule) for Nginx module's automated testing.
* The standard [headers](http://wiki.nginx.org/HttpHeadersModule) module and the 3rd-parth [headers-more](http://wiki.nginx.org/HttpHeadersMoreModule) module.

