FROM debian:buster-slim

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    git opam \
    pkg-config python3-dev python3-venv libsqlite3-dev

WORKDIR /hera
COPY . /hera/motifs
WORKDIR /hera/motifs
RUN python3 -m venv env && source env/bin/activate && python3 -m pip install -r analysis-requirements.txt
RUN opam init --bare --disable-sandboxing && \
    opam switch create 4.07.0 && \
    eval $(opam env) && \
    opam pin . -y
COPY . /hera/motifs
RUN eval $(opam env) && make

CMD ["performance.sh"]
