FROM golang:1.18-buster AS golang
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

FROM dart:stable as grpc-web
RUN set -ex \
    && apt-get update \
    && apt-get install -y libprotobuf-dev libprotoc-dev protobuf-compiler \
       automake build-essential git libtool make 

RUN git clone https://github.com/grpc/grpc-web /github/grpc-web

WORKDIR /github/grpc-web

RUN git checkout tags/1.2.1

## Install gRPC and protobuf

RUN ./scripts/init_submodules.sh

RUN cd third_party/grpc && make && make install

## Install all the gRPC-web plugin

RUN make install-plugin

FROM dart:stable
COPY --from=grpc-web /usr/local/bin /usr/local/bin
COPY --from=grpc-web /usr/local/include /usr/local/include
COPY --from=golang /go/bin/protoc-gen-go /usr/local/bin/
COPY --from=golang /go/bin/protoc-gen-go-grpc /usr/local/bin
RUN set -ex \
    && apt-get update \
    && apt-get install -y libprotobuf-dev libprotoc-dev protobuf-compiler \
    && dart pub global activate protoc_plugin \
    && cp $HOME/.pub-cache/bin/protoc-gen-dart /usr/local/bin 
 
ENTRYPOINT ["/usr/bin/protoc"]
