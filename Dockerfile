FROM ubuntu:16.04
MAINTAINER flowkey

RUN apt-get update && \
    apt-get install --yes \
        xvfb lib32z1 lib32stdc++6 build-essential \
        libcurl4-openssl-dev libglu1-mesa libxi-dev libxmu-dev libglu1-mesa-dev  \
        unzip wget lsof nano vim sudo rubygems ruby-dev \
        openjdk-8-jdk jq curl

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

RUN yes | sdkmanager --licenses && sdkmanager --update
RUN sdkmanager \
    "tools" \
    "platform-tools" \
    "ndk-bundle" \
    "build-tools;28.0.3" \
    "platforms;android-28" 

# install cmake
RUN curl -LOJ https://github.com/Kitware/CMake/releases/download/v3.15.1/cmake-3.15.1-Linux-x86_64.tar.gz
RUN tar xvzf cmake-3.15.1-Linux-x86_64.tar.gz
RUN mv cmake-3.15.1-Linux-x86_64 /opt/cmake
ENV PATH=/opt/cmake/bin:$PATH

# install ndk 16
RUN curl -LOJ https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
RUN unzip android-ndk-r16b-linux-x86_64.zip
RUN mv android-ndk-r16b /opt/android-ndk-r16b
ENV ANDROID_NDK_PATH /opt/android-ndk-r16b

# setup swift android toolchain
ADD setup.sh /opt/swift-android-toolchain/setup.sh
RUN chmod +x /opt/swift-android-toolchain/setup.sh
RUN /opt/swift-android-toolchain/setup.sh --clean

# publish on dockerhub
# docker build -t flowkey/androidswift5 . && docker push flowkey/androidswift5