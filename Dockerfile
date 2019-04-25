FROM ocaml/opam2:alpine

RUN sudo apk add sqlite-dev

WORKDIR /hera

RUN sudo chown -R opam /hera && git clone https://github.com/csmith49/graph-rules.git

WORKDIR /hera/graph-rules

RUN eval $(opam env) && opam depext && opam pin .
RUN eval $(opam env) && make