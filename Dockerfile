####################################################################################################
## Builder
####################################################################################################
FROM rust:alpine AS builder

# Create appuser
ENV USER=hello
ENV UID=10001

WORKDIR /app

ENV UPX_VERSION=4.0.1
ENV MAGICPAK_VERSION=1.3.2

# install upx for binary compression - https://upx.github.io/
ADD https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz /tmp/upx.tar.xz
RUN cd /tmp \
      && tar --strip-components=1 -xf upx.tar.xz \
      && mv upx /bin/ \
      && rm upx.tar.xz

# install magicpak - linker and bundler - https://github.com/coord-e/magicpak
ADD https://github.com/coord-e/magicpak/releases/download/v${MAGICPAK_VERSION}/magicpak-x86_64-unknown-linux-musl /usr/bin/magicpak
RUN chmod +x /usr/bin/magicpak

# copy the source code
COPY ./ .

# building the appication
RUN cargo build --target x86_64-unknown-linux-musl --release

# bundling
RUN /usr/bin/magicpak -v /app/target/x86_64-unknown-linux-musl/release/hello /bundle \
          --compress \
          --upx-arg --best

####################################################################################################
## Executor
####################################################################################################
FROM scratch
COPY --from=builder /bundle /.

CMD ["/app/target/x86_64-unknown-linux-musl/release/hello"]
