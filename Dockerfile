#
# inovex GitLab CI: Android v1.0
# Build Tools: v28.0.3
# Platforms: 27, 28
# https://hub.docker.com/r/inovex/gitlab-ci-android/
# https://www.inovex.de
#

FROM ubuntu:19.04
LABEL maintainer inovex GmbH

ENV SDK_TOOLS_VERSION "4333796"
ENV NDK_VERSION r18b

ENV ANDROID_HOME "/sdk"
ENV ANDROID_NDK_HOME "/ndk"
ENV PATH "$PATH:${ANDROID_HOME}/tools"

RUN apt-get -qq update && apt-get install -y locales \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.UTF-8

# install necessary packages
# prevent installation of openjdk-11-jre-headless with a trailing minus,
# as openjdk-8-jdk can provide all requirements and will be used anyway
RUN apt-get install -qqy --no-install-recommends \
    apt-utils \
    openjdk-8-jdk \
    checkstyle \
    openjdk-11-jre-headless- \
    libc6-i386 \
    lib32stdc++6 \
    lib32gcc1 \
    lib32ncurses-dev \
    lib32z1 \
    unzip \
    curl \
    cmake \
    lldb \
    git \
    ninja-build \
    build-essential \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# pre-configure some ssl certs
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# download and unzip sdk
RUN curl -s https://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS_VERSION}.zip > /tools.zip && \
    unzip /tools.zip -d /sdk && \
    rm -v /tools.zip

# Copy pkg.txt to sdk folder and create repositories.cfg
ADD pkg.txt /sdk
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg

# Accept licenses and update
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses > /dev/null && $ANDROID_HOME/tools/bin/sdkmanager --update

RUN while read -r pkg; do PKGS="${PKGS}${pkg} "; done < /sdk/pkg.txt && \
    ${ANDROID_HOME}/tools/bin/sdkmanager ${PKGS}

RUN mkdir /tmp/android-ndk && \
    cd /tmp/android-ndk && \
    curl -s -O https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
    unzip -q android-ndk-${NDK_VERSION}-linux-x86_64.zip && \
    mv ./android-ndk-${NDK_VERSION} ${ANDROID_NDK_HOME} && \
    cd ${ANDROID_NDK_HOME} && \
    rm -rf /tmp/android-ndk
