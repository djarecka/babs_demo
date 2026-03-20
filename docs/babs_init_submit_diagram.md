# BABS Init and Submit Diagram


## Workflow Steps

```mermaid
flowchart TD
    START([Start]) --> SETUP

    subgraph SETUP["Setup: Environment Variables"]
        S1["Create temp DEMO_DIR\n(babs_walkthrough_yoh_X8i/)"]
        S2["Set paths:\n• BABS_CONFIG_FILE\n• BABS_PROJECT\n• CONTAINER_DS\n• JOB_COMPUTE_SPACE"]
        S1 --> S2
    end

    SETUP --> STEP1

    subgraph STEP1["Step 1: Preparation"]
        P1["datalad create simbids-container/\n(container DataLad dataset)"]
        P2["datalad containers-add\nsimbids-0-0-3.sif → simbids-container/\n.datalad/environments/simbids-0-0-3/image"]
        P3["Write BABS config YAML\n(config_simbids_0-0-3_raw_mri.yaml)\n• SLURM partition/resources\n• conda env + apptainer module"]
        P1 --> P2 --> P3
    end

    STEP1 --> STEP2

    subgraph STEP2["Step 2: babs init"]
        direction TB
        I1["Create analysis/ DataLad dataset\n(YODA procedure)"]
        I2["Save babs_proj_config.yaml\n→ analysis/code/"]
        I3["Create output RIA store\nanalysis/ → my_BABS_project/output_ria/\nsiblings: output + output-storage"]
        I4["Create input RIA store\nanalysis/ → my_BABS_project/input_ria/\nsibling: input"]
        I5["Clone BIDS input dataset\n→ analysis/inputs/data/BIDS/\n(as subdataset)"]
        I6["Add container as subdataset\n→ analysis/containers/\n(from simbids-container/)"]
        I7["Generate run script\nanalysis/code/simbids-0-0-3_zip.sh\n• singularity run ...\n• 7z zip outputs"]
        I8["Generate job script\nanalysis/code/participant_job.sh"]
        I9["Determine subjects list\n→ analysis/code/processing_inclusion.csv"]
        I10["Generate submission templates\n• code/submit_job_template.yaml\n• code/check_setup/submit_test_job_template.yaml\n• code/check_setup/call_test_job.sh\n• code/check_setup/test_job.py"]
        I11["Drop input dataset file contents\n(keep only metadata/annex keys)"]
        I12["Publish analysis/ → input_ria/\n(refs/heads/master + git-annex)"]
        I13["Publish analysis/ → output_ria/\n(refs/heads/master + git-annex)"]
        I1 --> I2 --> I3 --> I4 --> I5 --> I6 --> I7 --> I8 --> I9 --> I10 --> I11 --> I12 --> I13
    end

    STEP2 --> POST

    subgraph POST["Post-init: Verify Setup"]
        V1["datalad get container image\nanalysis/containers/.datalad/environments/\nsimbids-0-0-3/image"]
    end

    POST --> END([BABS project ready])
```

## Resulting Directory Structure

```
DEMO_DIR/  (babs_walkthrough_yoh_X8i/)
├── simbids-container/               ← DataLad dataset (container)
│   └── .datalad/environments/
│       └── simbids-0-0-3/image      ← simbids-0.0.3.sif (annex)
├── config_simbids_0-0-3_raw_mri.yaml
├── job_compute_space/
└── my_BABS_project/                 ← BABS project root
    ├── analysis/                    ← DataLad dataset (YODA), ID: 3348251c-...
    │   ├── code/
    │   │   ├── babs_proj_config.yaml
    │   │   ├── simbids-0-0-3_zip.sh     ← runs container + zips output
    │   │   ├── participant_job.sh        ← SLURM job script
    │   │   ├── processing_inclusion.csv  ← subject/session list
    │   │   ├── submit_job_template.yaml
    │   │   └── check_setup/
    │   │       ├── submit_test_job_template.yaml
    │   │       ├── call_test_job.sh
    │   │       └── test_job.py
    │   ├── inputs/data/              ← subdataset (cloned input BIDS)
    │   ├── containers/               ← subdataset (simbids-container)
    │   └── logs/                     ← SLURM job logs (sim.e/o...)
    ├── input_ria/                    ← RIA store (input sibling)
    │   ├── 334/8251c-0e8a-4b1d-9fb3-af1b16e5b027/  ← analysis dataset (by UUID)
    │   ├── error_logs/
    │   └── ria-layout-version
    └── output_ria/                   ← RIA store (output + output-storage siblings)
        ├── 334/8251c-0e8a-4b1d-9fb3-af1b16e5b027/  ← analysis dataset (by UUID)
        ├── alias/data →              ← symlink to dataset in output_ria
        ├── error_logs/
        └── ria-layout-version
```

## Key DataLad Operations

| Operation | Command | Purpose |
|-----------|---------|---------|
| Create dataset | `datalad create` | Container dataset + analysis dataset |
| Add container | `datalad containers-add` | Register .sif in container dataset |
| Create RIA stores | `datalad create-sibling-ria` | Output RIA (results) + Input RIA (versioning) |
| Clone input data | `datalad install` | BIDS dataset as subdataset of analysis |
| Install container | `datalad install` | Container dataset as subdataset of analysis |
| Drop contents | `datalad drop` | Free disk space, keep annex keys |
| Publish | `datalad publish` | Push analysis branches to both RIA stores |
| Get file | `datalad get` | Retrieve container .sif for test job |
