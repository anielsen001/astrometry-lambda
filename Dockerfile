# Dockerfile example
# https://blog.mapbox.com/aws-lambda-python-magic-e0f6a407ffc6
FROM amazonlinux:latest

# set up build environment
RUN yum install -y yum-utils rpmdevtools python3 wget python-devel python3-devel
RUN yum groupinstall -y "Development Tools"
RUN pip3 install numpy

RUN yum -y install libjpeg libjpeg-devel cairo-devel fontconfig-devel libXrender-devel xorg-x11-proto-devel zlib-devel
RUN yum -y install netpbm-progs netpbm netpbm-devel

# download rpms so we can extract libraries and binaries
WORKDIR /tmp
RUN yumdownloader netpbm-10.79.00-7.amzn2.x86_64
RUN yumdownloader netpbm-progs-10.79.00-7.amzn2.x86_64
RUN yumdownloader file-5.11-33.amzn2.0.2.x86_64
RUN yumdownloader file-libs-5.11-35.amzn2.0.2.x86_64
RUN rpmdev-extract *rpm

# copy libs to /tmp/vendored
RUN mkdir -p /tmp/vendored/lib
RUN mkdir -p /tmp/vendored/bin
RUN mkdir -p /tmp/vendored/misc
RUN cp -r /tmp/*/usr/lib64/* /tmp/vendored/lib
RUN cp -r /tmp/file-*.amzn2.0.2.x86_64/usr/bin/* /tmp/vendored/bin
RUN cp -r /tmp/file-libs-*.amzn2.0.2.x86_64/usr/share/misc/* /tmp/vendored/misc
RUN cp -r /tmp/netpbm-progs-*.amzn2.x86_64/usr/bin/* /tmp/vendored/bin

# create a directroy to put things
RUN mkdir /root/lambda

# install cfitsio
WORKDIR /root
RUN wget http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-3.48.tar.gz
RUN tar xf cfitsio-3.48.tar.gz
RUN cd cfitsio-3.48 && ./configure --prefix=/root/lambda --enable-shared && make && make install && cd ..
ENV PKG_CONFIG_PATH=/root/cfitsio-3.48

# install astrometry.net
WORKDIR /root
RUN echo $PWD
RUN cd /root && wget http://astrometry.net/downloads/astrometry.net-latest.tar.gz 
RUN cd /root && tar xf astrometry.net-latest.tar.gz
ENV CFLAGS="-I/root/lambda/include"
ENV LDFLAGS="-L/root/lambda/lib"
# puts into /usr/local/astrometry
WORKDIR /root/astrometry.net-0.80
RUN make
RUN make py
RUN make extra
RUN make install
# RUN  cd /root/astrometry.net-* && make && make py && make extra && make install

RUN cd /root/lambda

RUN mkdir -p /tmp/vendored
RUN cp -R /usr/local/astrometry/* /tmp/vendored
RUN cp -R /root/lambda/* /tmp/vendored



RUN du -sh /tmp/vendored

# Create the zip file

RUN cd /tmp/vendored && zip -y -r9q /tmp/package.zip *
RUN du -sh /tmp/package.zip