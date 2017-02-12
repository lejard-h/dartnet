FROM google/dart:1.21.1

RUN pub global activate dartnet

ENV PATH $PATH:~/.pub-cache/bin

WORKDIR /dartnet

RUN cp ~/.pub-cache/bin/dartnet ./

ADD build /dartnet/build
ADD dartnet.yaml /dartnet/

EXPOSE 1337

ENTRYPOINT ["./dartnet"]