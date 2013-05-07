.PHONY: all install clean

all:
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/LuaJIT-2.0.1 && $(MAKE) TARGET_STRIP=@: CCDEBUG=-g PREFIX=/opt/lixen/luajit
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-cjson-1.0.3 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-redis-parser-0.10 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-rds-parser-0.05 && $(MAKE) DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/nginx-1.4.1 && $(MAKE)

install: all
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/LuaJIT-2.0.1 && $(MAKE) install TARGET_STRIP=@: CCDEBUG=-g PREFIX=/opt/lixen/luajit DESTDIR=$(DESTDIR)
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-cjson-1.0.3 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-redis-parser-0.10 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-rds-parser-0.05 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_INCLUDE_DIR=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/luajit-root/opt/lixen/luajit/include/luajit-2.0 LUA_LIB_DIR=/opt/lixen/lualib CC=gcc
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-dns-0.09 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-memcached-0.11 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-redis-0.15 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-mysql-0.13 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-string-0.08 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/lua-resty-upload-0.08 && $(MAKE) install DESTDIR=$(DESTDIR) LUA_LIB_DIR=/opt/lixen/lualib INSTALL=/var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/install
	cd /var/lib/lxc/home/dome/devel/lixen_app/ngx_openresty/ngx_openresty-1.2.8.1/build/nginx-1.4.1 && $(MAKE) install DESTDIR=$(DESTDIR)

clean:
	rm -rf build
