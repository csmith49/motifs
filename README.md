# Motifs

Synthesis of motifs, or graph rules, for heterogeneous entity extraction.

## Installation

With `opam` installed, the project can be compiled by navigating to this directory and running:

```bash
opam depext
opam pin .
make
```

This produces a general synthesis executable `./synthesize` and an evaluation executable `./evaluate`.

### Docker Installation

To improve portability, some infrastructure for running the code in a Docker container is provided. To build the docker image, simply navigate to this directory and run `docker build . --tag motifs`.

## Usage

### Main executable

The executables `./synthesize` and `./evaluate` takes several parameters, the most important of which is the *problem* file. A simple problem file is given below:

```json
{
    "metadata" : {
        "views" : ["simple_table"]
    },
    "files" : [
        "path/to/db/database.db",
        "path/to/other/db/database.db"
    ],
    "examples" : [
        {
            "file" : "path/to/ex/db/database.db",
            "example" : 12345
        }
    ]
}
```

The *metadata* field carries some relevant info for execution - in this case, which *view* is being used for synthesis. The *files* field contains absolute paths to database files we want our synthesized ensemble to run on. Lastly, the *examples* field contains *file* / *example* pairs.

Problem files are passed in using the *--problem* flag. For other flags, run `./executable --help`.

### Experiments

Three directories contain scripts for running experiments:

1. `analysis` - a Python module for constructing and evaluating ensembles over synthesized motifs
2. `scripts` - a collection of scripts for running ensembles and making graphs of performance
3. `data` - the directory containing all the data necessary for the scripts in `scripts`

The Python modules have very few dependencies, which can be found in `analysis-requirements.txt` or installed with `python3 -m pip install -r analysis-requirements.txt`.

### Data directory structure

The `data` directory contains a variety of sub-directories, each of which contain relevant information for an experiment. Given an experiment name `<experiment>`, the flow of information is roughly as follows:

1. Databases are stored in `data/db/<dataset>`. Each document is a separate `.db` file.
2. A *ground truth* file contains the ground-truth positive labels for a set of database files as a `.json` file. A ground truth file can either be provided directly via `data/default-gt/<experiment>.json` or constructed via a *sql* file `data/sql/<experiment>.json`, which contains the attribute `dataset` and a `SQL` command in the attribute `sql`.
3. Given a *ground truth* file, we construct the *problem* file `data/problem/<experiment>.json`, which is built from the *ground truth* file above and a *metadata* file `data/metadata/<experiment>.json`.
4. The problem file fully defines the synthesis constraints, so we can produce the relevant motifs in `data/motifs/<experiment>.json`.

I'll fill out the rest in a bit.

Note, an example data directory (and the one used for our experiments) can be found in [this repository](https://github.com/csmith49/motif-data).

## Out of Date Information

### Docker usage

To interact with the built Docker image, we run a container from the image with input and output directories bind-mounted at appropriate locations. This requires some configuration of the inputs.

Databases should be stored flat in a directory, along with a problem file named `problem.json` that references the stored databases using the prefix `/data`. That is, if we have data for a benchmark and store it in a directory called `benchmark`, our file structure looks like the following:

```txt
/benchmark
|-- problem.json
|-- database1.db
|-- database2.db
...
```

Any references to `database1.db` (or any other database) in `problem.json` should be given via the path `/data/database1.db`, *regardless of where `benchmark` is located on the host*.

Finally, an output directory should be prepared. Once the data is stored in an appropriate file, and the output directory is made, we run the image with the appropriate directories *bind-mounted* to the Docker image directories `/data` and `/output`. Usually, absolute paths are needed for this. For example, if we have the above benchmark directory at `/path/to/bm/benchmark`, and we've made an output directory at `/path/to/output`, we can run the following Docker command:

```bash
docker run -v /path/to/bm/benchmark:/data /path/to/output:/output gr:latest
```

This will spin up a container, run the synthesis on the `/path/to/bm/benchmark/problem.json` problem file, and save the output `.json` files to `/path/to/output/*.json` on the host file system.