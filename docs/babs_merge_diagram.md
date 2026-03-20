# BABS Merge Workflow Diagram

Based on `merge.txt`: `babs merge` collecting results from 3 completed jobs.

## DataLad/Git Operations

```mermaid
flowchart TD
    START([babs merge starts])

    START --> CLONE["datalad clone\noutput_ria → my_BABS_project/merge_ds/\n(temp working clone)\nconfigure output-storage sibling"]

    CLONE --> LIST["List all branches in output_ria\n→ finds 3 job branches:\n  job-10725927-1-sub-0001-ses-01\n  job-10725927-2-sub-0001-ses-02\n  job-10725927-3-sub-0002-ses-01"]

    LIST --> MERGE["git merge (octopus strategy) in merge_ds/\n  fast-forward → job-10725927-1-sub-0001-ses-01\n  simple merge  ← job-10725927-2-sub-0001-ses-02\n  simple merge  ← job-10725927-3-sub-0002-ses-01\n─────────────────────────────────────────────\ncreates 3 symlinks on master branch:\n  sub-0001_ses-01_fmriprep_anat-25-0-0.zip\n  sub-0001_ses-02_fmriprep_anat-25-0-0.zip\n  sub-0002_ses-01_fmriprep_anat-25-0-0.zip\n(symlinks → .git/annex/objects/...)"]

    MERGE --> PUSH_MASTER["git push\nmerge_ds/ master → output_ria/\n(a3eccfe → a1a1764)"]

    PUSH_MASTER --> PUSH_ANNEX["datalad publish\nmerge_ds/ git-annex → output_ria/\n(updates file availability records)"]

    PUSH_ANNEX --> CLEANUP["Cleanup:\ndatalad uninstall merge_ds/\n(remove temp clone)"]

    CLEANUP --> DEL["Delete job branches from output_ria:\n  job-10725927-1-sub-0001-ses-01 (was 56221f8)\n  job-10725927-2-sub-0001-ses-02 (was 4ed3ae0)\n  job-10725927-3-sub-0002-ses-01 (was 6dbadfa)"]

    DEL --> END([babs merge successful])

    END --> CLONE2["datalad clone\noutput_ria#~data\n→ tmp_dev/output/babs_walkthrough_yoh_X8i/\n(user-facing result dataset)"]

    CLONE2 --> RESULT["ls output/:\n  sub-0001_ses-01_fmriprep_anat-25-0-0.zip  →  annex symlink\n  sub-0001_ses-02_fmriprep_anat-25-0-0.zip  →  annex symlink\n  sub-0002_ses-01_fmriprep_anat-25-0-0.zip  →  annex symlink\n(metadata only; datalad get to retrieve bytes)"]
```

## Git Branch State: Before and After

```
output_ria/  BEFORE babs merge          output_ria/  AFTER babs merge
─────────────────────────────           ───────────────────────────────
master  (a3eccfe)                       master  (a1a1764)  ← octopus merge commit
job-10725927-1-sub-0001-ses-01          (branch deleted)
job-10725927-2-sub-0001-ses-02          (branch deleted)
job-10725927-3-sub-0002-ses-01          (branch deleted)
```

## Data Flow Summary

```
output_ria/
  job branches (3)
       │
       │  clone → merge_ds/  (temp)
       │       │
       │  git octopus merge all job branches → master
       │       │
       │  push master ──────────────────────────────> output_ria/ master (updated)
       │  push git-annex ──────────────────────────> output_ria/ git-annex (updated)
       │       │
       │  uninstall merge_ds/  (cleanup)
       │  delete job branches
       │
       │  datalad clone #~data alias
       └──────────────────────────────────────────> output/babs_walkthrough_yoh_X8i/
                                                    (3 zip symlinks, annex keys only)
```
