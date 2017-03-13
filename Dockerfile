FROM alpine:3.5
ADD https://github.com/libfann/fann/archive/2.2.0.tar.gz /home/abuild/
COPY *.patch /home/abuild/
RUN adduser -DG abuild abuild \
	&& apk update \
	&& apk upgrade \
	&& apk add alpine-sdk boost-dev cmake libressl-dev luajit-dev ragel rsync sed sudo \
	&& echo "abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild \
	&& chown abuild:abuild /home/abuild/2.2.0.tar.gz
USER abuild
RUN cd /home/abuild \
	&& tar xf 2.2.0.tar.gz \
	&& cd fann-2.2.0 \
	&& git apply ../fann.patch \
	&& cmake -DCMAKE_INSTALL_PREFIX=/home/abuild/fann . \
	&& make install \
	&& cd /home/abuild \
	&& git config --global user.email "you@example.com" \
	&& git config --global user.name "Your Name" \
	&& abuild-keygen -ai \
	&& git clone -b 3.5-stable https://github.com/alpinelinux/aports.git \
	&& cd aports \
	&& git apply /home/abuild/aports*patch \
	&& cd main/musl \
	&& abuild -r \
	&& cd ../icu \
	&& abuild -r \
	&& cd ../file \
	&& abuild -r \
	&& cd ../util-linux \
	&& abuild -r \
	&& cd ../gettext \
	&& abuild -r \
	&& cd ../glib \
	&& abuild -r \
	&& cd ../libevent \
	&& abuild -r \
	&& cd ../sqlite \
	&& abuild -r \
	&& cd ../../community/pcre2 \
	&& abuild -r \
	&& sudo apk add /home/abuild/packages/main/x86_64/*apk /home/abuild/packages/community/x86_64/*apk \
	&& cd /home/abuild \
	&& git clone https://github.com/01org/hyperscan.git \
	&& mv hyperscan git.hyperscan \
	&& cd git.hyperscan \
	&& git checkout v4.3.2 \
	&& cd .. \
	&& mkdir hyperscan build.hyperscan \
	&& cd build.hyperscan \
	&& cmake -DCMAKE_INSTALL_PREFIX=/home/abuild/hyperscan \
	-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-march=core2 -DCMAKE_CXX_FLAGS=-march=core2 ../git.hyperscan \
	&& make \
	&& make install/strip \
	&& cd /home/abuild/aports/testing/static-rspamd \
	&& abuild -r \
	&& sudo apk add /home/abuild/packages/testing/x86_64/rspamd*apk \
	&& sudo apk add busybox-static \
	&& mkdir -p /home/abuild/rootfs/etc \
	&& mkdir -p /home/abuild/rootfs/usr/share/misc \
	&& mkdir -p /home/abuild/rootfs/usr/bin \
	&& mkdir -p /home/abuild/rootfs/var/lib/rspamd \
	&& mkdir -p /home/abuild/rootfs/bin \
	&& cp /usr/sbin/rspamd /home/abuild/rootfs/usr/bin \
	&& cp /usr/bin/rspamc /home/abuild/rootfs/usr/bin \
	&& cp /usr/bin/rspamadm /home/abuild/rootfs/usr/bin \
	&& cp /bin/busybox.static /home/abuild/rootfs/bin \
	&& rsync -a /usr/share/rspamd /home/abuild/rootfs/usr/share \
	&& rsync -a /etc/rspamd /home/abuild/rootfs/etc \
	&& cp /usr/share/misc/magic.mgc /home/abuild/rootfs/usr/share/misc \
	&& rsync -a /etc/ssl /home/abuild/rootfs/etc/ssl \
	&& rsync -a /usr/share/ca-certificates /home/abuild/rootfs/usr/share \
	&& cd /home/abuild/rootfs/bin \
	&& for i in `./busybox.static --list`; do ln -s busybox.static ${i}; done
COPY passwd /home/abuild/rootfs/etc
COPY group /home/abuild/rootfs/etc
COPY worker-controller.inc /home/abuild/rootfs/etc/rspamd/override.d
COPY logging.inc /home/abuild/rootfs/etc/rspamd/override.d
COPY options.inc /home/abuild/rootfs/etc/rspamd/override.d
