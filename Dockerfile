FROM ocaml/opam2:alpine

RUN sudo apk add sqlite-dev

WORKDIR /hera

RUN sudo chown -R opam /hera && git clone https://github.com/csmith49/graph-rules.git

WORKDIR /hera/graph-rules

RUN eval $(opam env) && opam depext && opam pin .
ADD https://api.github.com/repos/csmith49/graph-rules/git/refs/heads/master version.json
RUN git pull && eval $(opam env) && make

RUN sudo chmod +x ./synthesis_entrypoint.sh
ENTRYPOINT ["sudo", "./synthesis_entrypoint.sh"]