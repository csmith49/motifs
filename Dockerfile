FROM ocaml/opam2:latest

RUN sudo apt-get update && sudo apt-get install -y \
    pkg-config \
    python3-dev \
    libsqlite3-dev

WORKDIR /hera

RUN sudo chown -R opam /hera && git clone https://github.com/csmith49/motifs.git

WORKDIR /hera/motifs

RUN eval $(opam env) && opam depext && opam pin .
ADD https://api.github.com/repos/csmith49/motifs/git/refs/heads/master version.json
RUN git pull && eval $(opam env) && make

CMD ["make", "experiments"]