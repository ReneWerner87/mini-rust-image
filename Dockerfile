####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

# Create appuser
ENV USER=hello
ENV UID=10001

WORKDIR /hello

COPY ./ .

RUN cargo build --target x86_64-unknown-linux-musl --release

ENV UPX_VERSION=4.0.1

ADD https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz /tmp/upx.tar.xz
RUN cd /tmp \
      && tar --strip-components=1 -xf upx.tar.xz \
      && mv upx /bin/ \
      && rm upx.tar.xz

ADD https://github.com/coord-e/magicpak/releases/download/v1.3.2/magicpak-x86_64-unknown-linux-musl /usr/bin/magicpak
RUN chmod +x /usr/bin/magicpak



RUN /usr/bin/magicpak -v /hello/target/x86_64-unknown-linux-musl/release/hello /bundle \
          --compress                               \
          --upx-arg --best

FROM scratch
COPY --from=0 /bundle /.

CMD ["/hello/target/x86_64-unknown-linux-musl/release/hello"]
