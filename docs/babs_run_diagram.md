# BABS Submit Workflow Diagram (per-job)

Based on `submit.txt`: single SLURM job for `sub-0001 ses-01` (job ID: 10725927).

## DataLad/Git Operations

```mermaid
flowchart TD
    START([SLURM job starts\njob-10725927-1-sub-0001-ses-01])

    START --> CLONE["Clone analysis/ (from input_ria)\n→ job_compute_space/job-10725927-1-sub-0001-ses-01/ds/\n(isolated working copy for this job)"]

    CLONE --> GET["datalad get  [from: origin = input_ria]\ninputs/data/BIDS/sub-0001/ses-01/\n• anat/  T2w .json + .nii.gz\n• dwi/   AP/PA run-01/02 .json + .nii.gz\n• func/  AP/PA rest bold .json + .nii.gz\n• dataset_description.json"]

    GET --> SCI["[ scientific workflow - omitted ]"]

    SCI --> ZIP["7z: zip outputs/fmriprep_anat/\n→ sub-0001_ses-01_fmriprep_anat-25-0-0.zip\n(750 items, 185 KiB)"]

    ZIP --> DLRUN["datalad run\nbash ./code/simbids-0-0-3_zip.sh sub-0001 ses-01\n(records provenance of the run)"]

    DLRUN --> SAVE["datalad save\nadd:  sub-0001_ses-01_fmriprep_anat-25-0-0.zip\nsave: ds/ (dataset)"]

    SAVE --> PUSH_ANNEX["git-annex copy\nzip file content → output-storage sibling\n(file bytes → output_ria annex)"]

    PUSH_ANNEX --> PUSH_GIT["git push\njob branch with provenance records\n→ output sibling (output_ria)"]

    PUSH_GIT --> END([SUCCESS])
```

## Data Flow Summary

```
input_ria/                          job_compute_space/
(origin)                            job-10725927-1-sub-0001-ses-01/ds/
    │                                       │
    │  ── datalad get (annex) ──────────>   inputs/data/BIDS/sub-0001/ses-01/
    │  ── git clone (metadata) ──────────>  code/, .datalad/, ...
    │                                       │
    │                                  [scientific workflow]
    │                                       │
    │                                  sub-0001_ses-01_fmriprep_anat-25-0-0.zip
    │                                       │
    │                           datalad run + save (provenance commit)
    │                                       │
    │                          ┌────────────┴───────────────┐
    │                          ▼                            ▼
    │                   output_ria/                  output_ria/
    │                   (output-storage)             (output)
    │                   file bytes (annex)           git branch (provenance)
```
