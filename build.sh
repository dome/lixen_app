#!/bin/bash
make clean
./configure --with-luajit  --with-http_mp4_module --with-http_stub_status_module --prefix=/opt/lixen
make

