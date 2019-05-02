# Graph Rules

Synthesis of graph rules for heterogeneous entity extraction.

## Installation

With `opam` installed, the project can be compiled by navigating to this directory and running:

```bash
opam depext
opam pin .
make
```

This produces a set of utility scripts in the `./scripts` directory, and a general synthesis executable in the form of `./gr`.

### Docker Installation

To improve portability, some infrastructure for running the code in a Docker container is provided. To build the docker image, simply navigate to this directory and run `docker build -t gr .`.

## Usage

### Main executable

The main executable `./gr` takes several parameters, the most important of which is the *problem* file. A simple problem file is given below:

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

Problem files are passed in using the *-p* flag. For other flags, run `./gr --help`.

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