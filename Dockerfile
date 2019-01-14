FROM phusion/baseimage:0.9.19

ENV LANG=en_US.UTF-8

RUN \
    apt-get update && \
    apt-get install -y \
        autoconf \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        cmake \
        g++ \
        doxygen \
        git \
        libboost-all-dev \
        libreadline-dev \
        libssl-dev \
        libtool \
        make \
        ncurses-dev \
        pbzip2 \
        pkg-config \
        python3 \
        python3-dev \
        python3-jinja2 \
        python3-pip \
        nginx \
        fcgiwrap \
        s3cmd \
        awscli \
        jq \
        wget \
        gdb 

RUN \ 
    apt-get install -y \
        libboost-chrono-dev \
        libboost-context-dev \
        libboost-coroutine-dev \
        libboost-date-time-dev \
        libboost-filesystem-dev \
        libboost-iostreams-dev \
        libboost-locale-dev \
        libboost-program-options-dev \
        libboost-serialization-dev \
        libboost-signals-dev \
        libboost-system-dev \
        libboost-test-dev \
        libboost-thread-dev \
        libncurses5-dev \
        libreadline-dev \
        perl

# Optional packages (not required, but will make a nicer experience)
RUN \
    apt-get install -y \
    doxygen \
    libncurses5-dev \
    libreadline-dev \
    perl

RUN git clone https://gitlab.com/beyondbitcoin/whaleshares-chain.git

WORKDIR /whaleshares-chain

RUN  \
#    git checkout master && \
    git checkout alloc_exploit && \
    git submodule update --init --recursive

WORKDIR /whaleshares-chain/build

RUN \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local/whaleshares \
        -DCMAKE_BUILD_TYPE=Release \
        -DLOW_MEMORY_NODE=OFF \    
        .. 

RUN make -j$(nproc) whaled
RUN make -j$(nproc) cli_wallet
RUN make install  # /usr/local/whaleshares

RUN \
  cd .. && \
    ( /usr/local/whaleshares/bin/whaled --version \
      | grep -o '[0-9]*\.[0-9]*\.[0-9]*' \
      && echo '_' \
      && git rev-parse --short HEAD ) \
      | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g' \
      > /etc/whaledversion && \
    cat /etc/whaledversion 

RUN \
    rm -rf /usr/local/whaleshares/build && \
    rm -rf /usr/local/whaleshares/include && \
    rm -rf /usr/local/whaleshares/lib

RUN \
    apt-get remove -y \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        cmake \
        doxygen \
        dpkg-dev \
        git \
        libboost-all-dev \
        libc6-dev \
        libexpat1-dev \
        libgcc-5-dev \
        libhwloc-dev \
        libibverbs-dev \
        libicu-dev \
        libltdl-dev \
        libncurses5-dev \
        libnuma-dev \
        libopenmpi-dev \
        libpython-dev \
        libpython2.7-dev \
        libreadline-dev \
        libreadline6-dev \
        libssl-dev \
        libstdc++-5-dev \
        libtinfo-dev \
        libtool \
        linux-libc-dev \
        m4 \
        make \
        manpages \
        manpages-dev \
        mpi-default-dev \
        python-dev \
        python2.7-dev \
        python3-dev \
    && \
    apt-get autoremove -y && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /var/cache/* \
        /usr/include \
        /usr/local/include


RUN useradd -s /bin/bash -m -d /var/lib/whaleshares whaled

ENV HOME /var/lib/whaleshares
RUN chown whaled:whaled -R /var/lib/whaleshares

VOLUME ["/var/lib/whaleshares"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 2001

# add seednodes from documentation to image
ADD doc/seednodes.txt /etc/whaled/seednodes.txt

# the following adds lots of logging info to stdout
ADD contrib/fullnode.config.ini /etc/whaled/fullnode.config.ini
ADD contrib/witness.config.ini /etc/whaled/witness.config.ini

# add normal startup script that starts via sv
ADD contrib/whaled.run /usr/local/bin/whaled-sv-run.sh
RUN chmod +x /usr/local/bin/whaled-sv-run.sh

# add nginx templates
ADD contrib/whaled.nginx.conf /etc/nginx/whaled.nginx.conf
ADD contrib/healthcheck.conf.template /etc/nginx/healthcheck.conf.template
ADD contrib/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/healthcheck.sh



# entry point
ADD contrib/whaledentrypoint.sh /usr/local/bin/whaledentrypoint.sh
RUN chmod +x /usr/local/bin/whaledentrypoint.sh
CMD /usr/local/bin/whaledentrypoint.sh

