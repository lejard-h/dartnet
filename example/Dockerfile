FROM google/dart

RUN pub global activate dartnet
ENV PATH $PATH:~/.pub-cache/bin

WORKDIR /dartnet

RUN cp ~/.pub-cache/bin/dartnet ./
ADD web /dartnet/web
ADD dartnet.yaml /dartnet/

EXPOSE 1337

ENTRYPOINT ["./dartnet", "-c", "dartnet.yaml"]