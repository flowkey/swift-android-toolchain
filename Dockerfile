FROM ubuntu:16.04
MAINTAINER flowkey

RUN apt-get update && \
    apt-get install --yes \
        xvfb lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev libglu1-mesa-dev  \
        unzip wget lsof vim sudo rubygems ruby-dev \
        openjdk-8-jdk jq curl git && \
    rm -rf /var/lib/apt/lists/*

# fastlane
RUN gem install fastlane -NV

# node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@6.x.x && \
    node -v && npm -v

# android
ARG sdk_version=sdk-tools-linux-4333796.zip
ARG android_home=/opt/android/sdk

RUN mkdir -p ${android_home} && \
    curl --silent --show-error --location --fail --retry 3 --output /tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

ENV ANDROID_HOME ${android_home}
ENV PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN yes | sdkmanager --licenses && sdkmanager --update && \
    sdkmanager \
        "tools" \
        "platform-tools" \
        "build-tools;28.0.3" \
        "platforms;android-28"

# install cmake
RUN curl -LOJ https://github.com/Kitware/CMake/releases/download/v3.15.1/cmake-3.15.1-Linux-x86_64.tar.gz && \
    tar xvzf cmake-3.15.1-Linux-x86_64.tar.gz && rm cmake-*.tar.gz && \
    mv cmake-3.15.1-Linux-x86_64 /opt/cmake
ENV PATH=/opt/cmake/bin:$PATH

# install ninja 1.9.0
RUN curl -LOJ https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-linux.zip && \
    unzip ninja-linux.zip && rm ninja-linux.zip && \
    mv ninja /opt/ninja/bin
ENV PATH=/opt/ninja/bin:$PATH

# install ndk 16b
RUN curl -LOJ https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip && \
    unzip android-ndk-r16b-linux-x86_64.zip && rm android-ndk-*.zip && \
    mv android-ndk-r16b $ANDROID_HOME/ndk-bundle
ENV ANDROID_NDK_PATH $ANDROID_HOME/ndk-bundle

# setup swift android toolchain
ADD setup.sh libs cmake_caches.cmake /opt/swift-android-toolchain
RUN chmod +x /opt/swift-android-toolchain/setup.sh
RUN /opt/swift-android-toolchain/setup.sh
ENV SWIFT_ANDROID_TOOLCHAIN_PATH /opt/swift-android-toolchain

# publish on dockerhub
# docker build -t flowkey/androidswift5 . && docker push flowkey/androidswift5