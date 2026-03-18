
### Running Babs

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

### Merging Babs output

After all of the jobs finish (you can check running `babs status $BABS_PROJECT`), run the merging script (the script does not unzip the files)
```
bash babs_walkthrough_merge.sh
```
