FROM ubuntu:22.04
# Build and install latest bacnet-stack tools

COPY bacnet-wrapper /
COPY simulator /

RUN apt-get update && apt-get -y install build-essential git perl ca-certificates \
	&& update-ca-certificates \
	&& git clone --depth 1 https://github.com/bacnet-stack/bacnet-stack.git \
	&& cd bacnet-stack \
	&& make \
	&& rm -f bin/*.txt bin/*.bat \
	&& mv bin/* /usr/local/bin \
	&& chmod a+x /bacnet-wrapper \
	&& cd / \
	&& rm -rf /bacnet-stack* \
	&& apt-get -y remove --purge build-essential git \
	&& apt-get -y autoremove \
	&& apt-get -y autoclean \
	&& rm -rf /var/lib/apt/lists/*

EXPOSE 47808/udp

CMD ["/bacnet-wrapper"]
