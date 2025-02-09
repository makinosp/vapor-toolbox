FROM swift:6.0 AS builder
WORKDIR /build
COPY . .
RUN swift build --build-path /build/toolbox --static-swift-stdlib -c release

FROM swift:6.0 AS runner
COPY --from=builder /build/toolbox/release/vapor /usr/bin

ENTRYPOINT ["vapor"]
