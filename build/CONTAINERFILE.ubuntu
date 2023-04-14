FROM eclipse-temurin:11-focal

RUN apt update && apt install -y curl scala ant git nodejs npm build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev
RUN curl -fL https://github.com/coursier/coursier/releases/latest/download/cs-x86_64-pc-linux.gz | gzip -d > cs && chmod +x cs && ./cs setup --install-dir /usr/local/bin/
RUN mkdir /orbeon
COPY compile/build.sh /
VOLUME ["/orbeon"]
WORKDIR /orbeon
CMD ["/bin/bash", "/build.sh"]
