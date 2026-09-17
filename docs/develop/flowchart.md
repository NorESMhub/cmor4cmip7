# Flowchart

This page describes the workflow of the program in different level of details, from overall CMOR workflow to the specific processing steps.

## 1. General workflow

General workflow: the overall data path from recipe to validated output.

The top-level view is a recipe-driven pipeline: configuration files define the experiment, model metadata, runtime directories, and target variables; the program reads these inputs and writes CMIP7-compliant output.

```mermaid
%%{init: {"flowchart": {"wrappingWidth": 800}}}%%
%%{init: {"themeVariables": { "fontSize": "24px" }}}%%
flowchart TB
    A["Prepare recipes for experiment"] --> B["Compile program"]
    B --> C["Read namelists"]
    C --> D["Ingest raw model output"]
    D --> E["Map variables to CMIP7 conventions"]
    E --> F["Write CMOR NetCDF output"]
    F --> G["Validate and archive results"]
```

## 2. Program-level flow

Program-level flow: how the executable coordinates the runtime steps.

At the program level, `cmor4cmip7.F90` acts as the entry point. It loads the configuration, builds the file list, dispatches to model-specific processing routines, and loop through the list of variables, write out CMIP7-compliant datasets until all required variables are processed.

```mermaid
%%{init: {"flowchart": {"wrappingWidth": 1024}}}%%
%%{init: {"themeVariables": { "fontSize": "48px" }}}%%
flowchart TB
    A["main program<br/>(cmor4cmip7.F90)"] --> B["read namelists<br/>(m_namelists.F90)"]
    B --> C["create file list, scan input directories<br/>(scan_files())"]
    C --> D["loop over model components"]
    D --> E["call component routine<br/>for example: ocn2cmor"]
    E --> F["read mapping metadata<br/>(m_jsons.F90)"]
    F --> G["process variables and time slices<br/>(open_ofile(), add_tslices())"]
    G --> H["write output through CMOR API <br/> (write_tslices())"]
    H --> I["finish and return <br/>(deallocate())"]
```

## 3. Detailed ocean processing flow

Detailed component flow: how one model component translates native fields into CMIP7 variables.

The ocean path is a representative example of how a component routine converts native output into CMIP7 output. The logic reads the relevant input files, looks up the target metadata, applies preprocessing and postprocessing, and writes the values through the CMOR interface.

```mermaid
%%{init: {"flowchart": {"wrappingWidth": 1024}}}%%
%%{init: {"themeVariables": { "fontSize": "48px" }}}%%
flowchart TB
    subgraph OCN["Ocean processing (m_modelsocn.F90)"]
        direction TB
        A1["ocn2cmor"] --> A2["scan files and read grid info"]
        A2 --> A3["loop over realms, frequencies and variables"]
        A3 --> A4["JSON lookups for metadata <br/>(m_json.F90)"]
        A4 --> A5["define output files<br/>(open_ofile())"]
        A5 --> A6["special preprocess <br/> special_pre()"]
        A6 --> A7["read in model output <br/> read_tslice()"]
        A7 --> A8["special postprocess <br/> special_post()"]
        A8 --> A9["write time slices <br/> write_tslice()"]
        A9 --> A10["manage chunking <br/> (cleanup and close)"]

        %% Invisible node containing spacing to force width
        inv[&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;]
        style inv fill:none,stroke:none,color:none
    end

    M["main<br/>cmor4cmip7.F90"] --> A1
    A1 --> B1["CMIP7 tables and mapping files"]
    B1 --> A4
```


## 5. Typical processing workflow

The actual variable conversion pattern is usually:

1. discover the native file and grid metadata;
2. identify the target CMIP7 variable and its associated metadata;
3. read the source model field(s);
4. apply any preprocessing or derivation required by the mapping;
5. convert units, dimensions, and time axes to the CMIP7 convention;
6. write the result through the CMOR API.

This pattern repeats for each variable and time slice of different realm, frequency, and region until the run is complete.
