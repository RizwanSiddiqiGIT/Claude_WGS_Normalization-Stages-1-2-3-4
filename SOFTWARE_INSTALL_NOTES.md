# Software Install Notes

Run system installs from a root WSL shell when automation cannot answer `sudo` prompts:

```powershell
wsl -d Ubuntu -u root --exec bash -c 'apt-get update'
wsl -d Ubuntu -u root --exec bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y fastqc multiqc fastp bwa-mem2 samtools bcftools tabix parallel docker.io default-jre'
```

Picard is expected at:

```text
/home/rayzw/tools/picard/picard.jar
```

DeepVariant runs through Docker image:

```text
google/deepvariant:1.6.0
```

Keep active pipeline paths under native WSL storage:

```text
/home/rayzw/DNA
```

