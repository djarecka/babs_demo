### Preparing the environment

If you have `uv` it should be as trivial as

```
uv venv && source .venv/bin/activate && uv pip install -r requirements.txt
```

and continuing to the next steps.

If you need "bleeding edge" babs, do in addition

```
uv pip install git+https://github.com/PennLINC/babs
```


### Running Babs with a BIDS study layout

This approach uses a persistent BIDS study directory (`BABS_BIDS_STUDY_DIR`) with
raw data as a subdataset and BABS project output under `derivatives/`.

Set `BABS_BIDS_STUDY_DIR`, `BABS_BIDS_CONTAINER_DIR`, and `BABS_BIDS_WORKDIR` (for the computation space), as well as your HPC settings,
in your `.env` file before running. You can check [the example from MIT](.env.mit) 

1. Prepare the BIDS study layout (build the Singularity image, generate simulated data, set up the datalad dataset structure):
```
bash babs_walkthrough_prepare_bids_layout.sh
```
The layout of BABS_BIDS_STUDY_DIR after this step:
```
BABS_BIDS_STUDY_DIR/
  sourcedata/
    raw/          (datalad subdataset with simulated BIDS data)
        dataset_description.json
        sub-001/
        sub-002/        
  derivatives/
    .gitkeep
```

2. Initialize and submit BABS jobs:

Note: By default the `ANALYSIS_PATH` is set to `.`, but you can change it in the script.
```
bash babs_walkthrough_bids_layout.sh
```
The layout of `BABS_BIDS_STUDY_DIR` after this step:
```
BABS_BIDS_STUDY_DIR/
  sourcedata/
    raw/
  derivatives/
    <babs_project_dir>/
      .babs/              (hidden: input_ria/, output_ria/, babs_init_config.yaml)
      CHANGELOG.md
      README.md
      code/
      containers/
      logs/
      sourcedata/
```

3. After all jobs finish, merge and extract results (pass the BABS project directory as a full path or relative to `BABS_BIDS_STUDY_DIR/derivatives/`):
```
bash babs_walkthrough_merge_bids_layout.sh <path>
```
The layout of `BABS_BIDS_STUDY_DIR` after this step:
```
BABS_BIDS_STUDY_DIR/
  sourcedata/
    raw/
  derivatives/
    <babs_project_dir>/
      .babs/              (hidden: input_ria/, output_ria/, babs_init_config.yaml)
      CHANGELOG.md
      README.md
      code/
      containers/
      dataset_description.json
      logs/
      sourcedata/
      sub-0001/
      sub-0002/
```

### Running Babs (older version of the demo, without enforcing bids layout)

You have two options to prepare data and run Babs:

1. Preparing data/containers in the isolated dir
```
bash babs_walkthrough.sh
```

2. Prepare data and the singularity image first and run babs later

- create  data and the singularity image in `babs_walkthrough_preparation` directory
```
bash babs_walkthrough_prepare.sh
```
- run Babs using data and container from `babs_walkthrough_preparation` directory
```
bash babs_walkthrough.sh --skip-data-prep
```
- run Babs init only (you can submit the jobs later)
```
bash babs_walkthrough.sh --init-only
```

### Merging Babs output

After all of the jobs finish (you can check running `babs status $BABS_PROJECT`), run the merging script (the script does not unzip the files)
```
bash babs_walkthrough_merge.sh
```
