# `experiment.nml`

The `experiment` namelist defines the experiment metadata required for CMIP7 output. It captures the experiment identity, the parent/child branch information, the variant label components, and the temporal coverage of the run. These are the metadata elements used to construct the CMIP7 Data Reference Syntax (DRS) and to describe how a simulation relates to its parent run.

The CMIP7 guidance defines these as part of the required and conditionally required global attributes for model output. In particular, the experiment identifier, the activity, the variant indices, and the parent experiment information should be consistent with the registered experiment definition and the model branch history.

```fortran
&experiment
 casename               = 'n1850.ne16pg3_tn14.noresm3_0_beta22.bdmc2_1p2.20260811',
 osubdir                = 'NorESM3-LM/piControl/v20260914',
 experiment_id          = 'piControl',
 parent_experiment_id   = 'piControl-spinup',
 parent_experiment_rip  = 'r1i1p1',
 parent_time_units      = 'days since 0421-01-01',
 history                = '',
 realization_index      = 'r1',
 initialization_index   = 'i1',
 physics_index          = 'p1',
 forcing_index          = 'f1',
 branch_time            = 0.,
 year1                  = 1346,
 yearn                  = 1395,
 month1                 = 1,
 monthn                 = 12,
 activity_id            = 'CMIP',
 parent_activity_id     = 'CMIP',
 parent_variant_label   = 'r1i1p1f1',
 parent_mip_era         = 'CMIP7',
 mip_era                = 'CMIP7',
 branch_time_in_child   = 0.0D0,
 branch_time_in_parent  = 430700.0D0,
 scanallfiles           = .false.
/
```

## Key CMIP7 concepts

The most important fields in this namelist are:

- `experiment_id`: the short label identifying the experiment, such as `piControl`, `historical`, or `abrupt-4xCO2`.
- `activity_id`: the activity responsible for the experiment and the data, such as `CMIP`.
- `realization_index`, `initialization_index`, `physics_index`, `forcing_index`: the four parts of the CMIP7 variant label, usually combined as `r<i>i<p>f<...>` or `r1i1p1f1`.
- `parent_experiment_id`, `parent_variant_label`, `parent_mip_era`: the metadata needed to trace the run back to the parent simulation when the current experiment is a branch.
- `branch_time_in_child` and `branch_time_in_parent`: the times at which the branch occurred in the child and parent simulations.

## Field descriptions

| keyword | CMIP7-aligned description |
| --- | --- |
| `casename` | Name of the model run or case, typically containing the model, experiment, ensemble member, and run date. |
| `osubdir` | Output subdirectory path describing the archive location for the experiment and version in the CMIP7 directory hierarchy. |
| `experiment_id` | Short experiment identifier, as defined in the CMIP7 controlled vocabulary for experiment labels. |
| `parent_experiment_id` | Experiment label of the parent simulation from which the current experiment was branched. |
| `parent_experiment_rip` | Parent run variant identifier, typically in the form `r...i...p...f...`, used to identify the parent ensemble member. |
| `parent_time_units` | Time units used in the parent simulation, for example `days since 0421-01-01`. |
| `history` | Optional CF-style processing history describing how the dataset was produced or transformed. |
| `realization_index` | Realization index, part of the CMIP7 variant label; for example `r1`, `r2`, or `r12`. |
| `initialization_index` | Initialization index, part of the CMIP7 variant label; for example `i1` or `i196001`. |
| `physics_index` | Physics index, part of the CMIP7 variant label; for example `p1` or `p3`. |
| `forcing_index` | Forcing index, part of the CMIP7 variant label; for example `f1` or `f6`. |
| `branch_time` | Time in the child simulation at which the branch from the parent simulation occurred, expressed in the child time units. |
| `year1` | First year of the temporal coverage represented by the output file or dataset. |
| `yearn` | Final year of the temporal coverage represented by the output file or dataset. |
| `month1` | First month of the temporal coverage represented by the output file or dataset. |
| `monthn` | Final month of the temporal coverage represented by the output file or dataset. |
| `activity_id` | Activity acronym for the experiment, such as `CMIP`, as defined in the CMIP7 controlled vocabularies. |
| `parent_activity_id` | Activity acronym of the parent experiment. |
| `parent_variant_label` | Full parent simulation variant label identifying the parent realization, initialization, physics, and forcing indices. |
| `parent_mip_era` | MIP era associated with the parent experiment, such as `CMIP6` or `CMIP7`. |
| `mip_era` | MIP era for the dataset; CMIP7 files should use `CMIP7`. |
| `branch_time_in_child` | Time in the child simulation when the branch occurred, expressed in the child simulation's time units and calendar. |
| `branch_time_in_parent` | Time in the parent simulation when the branch occurred, expressed in the parent simulation's time units and calendar. |
| `scanallfiles` | Logical switch controlling whether all files in the target output set are scanned when determining file coverage. |

:::{note}
For CMIP7, these values should be internally consistent with the registered experiment definition, the `source_id`, and the variant information used in the file metadata. When a simulation is a branch of an earlier experiment, the parent metadata must clearly record the parent experiment identity, the parent variant label, and the parent branch time so that users can trace the lineage of the simulation.
:::

:::{important}
**Code and dataset versions:**
The processed dataset version should match the [code release tag](https://github.com/NorESMhub/cmor4cmip7/tags). This keeps the output traceable and reproducable. It will be easiber to identify errors in the CMORized and published datasets, and facilitate the [data errata record and retract processes](https://errata.esgf.io/static/index.html).
:::

