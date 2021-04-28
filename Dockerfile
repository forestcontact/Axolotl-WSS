FROM ghcr.io/graalvm/graalvm-ce:latest as builder
ENV GRAALVM_HOME=/opt/graalvm-ce-java11-21.1.0/ 
SHELL ["/usr/bin/bash", "-c"]
WORKDIR /app
RUN microdnf install -y git zlib-devel && rm -rf /var/cache/yum
RUN gu install native-image
RUN git clone https://github.com/i-infra/signal-cli
WORKDIR /app/signal-cli
RUN git fetch -a && git checkout 9d3dc8f7350e1d36367ef20e53e6235daf65b475 
RUN ./gradlew build && ./gradlew installDist
RUN md5sum ./build/libs/* 
RUN ./gradlew assembleNativeImage

FROM gcr.io/distroless/cc:debug
SHELL ["/busybox/ash", "-c"]
RUN mkdir -p /app/data
WORKDIR /app
ENV LD_LIBRARY_PATH=/lib64
#RUN wget -q https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb && dpkg -i cloudflared-stable-linux-amd64.deb
#RUN wget -q https://github.com/vi/websocat/releases/download/v1.8.0/websocat_1.8.0_newer_amd64.deb && dpkg -i websocat_1.8.0_newer_amd64.deb
RUN wget -q -O websocat https://github.com/vi/websocat/releases/download/v1.8.0/websocat_amd64-linux-static
RUN wget -q -O cloudflared https://github.com/cloudflare/cloudflared/releases/download/2021.4.0/cloudflared-linux-amd64
RUN wget -q -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
RUN wget -q -O curl https://github.com/moparisthebest/static-curl/releases/download/v7.76.1/curl-amd64
RUN chmod +x ./curl ./jq ./cloudflared ./websocat
COPY --from=builder /app/signal-cli/build/native-image/signal-cli /app
COPY --from=builder /lib64/libz.so.1 /lib64
COPY ./link.sh /app
COPY ./launch.sh /app
RUN ln -s /busybox/ash /bin/sh
ENTRYPOINT ["/busybox/ash", "/app/launch.sh"]
