FROM ocaml/opam2:latest

RUN sudo apt-get update && sudo apt-get install -y \
    pkg-config \
    python3-dev \
    python3-venv \
    libsqlite3-dev

WORKDIR /hera

RUN sudo chown -R opam /hera && git clone https://github.com/csmith49/motifs.git
RUN python3 -m venv env && source env/bin/activate && python3 -m pip install -r analysis-requirements.txt

WORKDIR /hera/motifs
RUN sudo rm -rf data

RUN eval $(opam env) && opam depext && opam pin .
ADD https://api.github.com/repos/csmith49/motifs/git/refs/heads/master version.json
RUN git pull && eval $(opam env) && make

RUN git clone https://github.com/csmith49/motif-data.git data
ADD https://api.github.com/repos/csmith49/motif-data/git/refs/heads/master data-version.json

CMD ["make", "experiments"]