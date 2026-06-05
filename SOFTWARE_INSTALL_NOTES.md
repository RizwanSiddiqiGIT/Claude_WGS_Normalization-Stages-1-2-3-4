# Software Install Notes

Run system installs from a root WSL shell when automation cannot answer `sudo` prompts:

```powershell
wsl -d Ubuntu -u root --exec bash -c 'apt-get update'
wsl -d Ubuntu -u root --exec bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y fastqc multiqc fastp bwa bwa-mem2 samtools bcftools tabix parallel default-jre'
```

Install FASTQ/BGZF validation helpers:

```powershell
wsl -d Ubuntu -u root --exec apt-get update
wsl -d Ubuntu -u root --exec apt-get install -y seqkit bbmap
```

This also installs `pigz` as a dependency in the current Ubuntu package set.

Expected paths/versions:

```text
/usr/bin/seqkit      seqkit v2.10.1
/usr/bin/reformat.sh BBTools version 39.20
/usr/bin/pigz        pigz 2.8
```

Picard is expected at:

```text
/home/rayzw/tools/picard/picard.jar
```

Install Picard:

```bash
mkdir -p /home/rayzw/tools/picard
cd /home/rayzw/tools/picard
curl -fL https://github.com/broadinstitute/picard/releases/download/3.4.0/picard.jar -o picard.jar
java -jar picard.jar MarkDuplicates --version
```

DeepVariant runs through Docker image:

```text
google/deepvariant:1.6.0
```

In the current restored WSL setup, plain `docker` does not execute inside Ubuntu unless Docker Desktop WSL integration is enabled. Use `docker.exe` through Windows interop after Docker Desktop is running:

```bash
docker.exe version
docker.exe pull google/deepvariant:1.6.0
docker.exe image inspect google/deepvariant:1.6.0
```

If `docker.exe version` reports that `npipe:////./pipe/docker_engine` is missing, start Docker Desktop and retry.

Keep active pipeline paths under native WSL storage:

```text
/home/rayzw/DNA
```

Known reinstall fixes completed:

- Installed `fastqc`, `multiqc`, `fastp`, `bwa-mem2`, and `parallel` from Ubuntu apt.
- Installed classic `bwa` from Ubuntu apt after `bwa-mem2` repeatedly stalled on a tiny real-read block during Stage 2 mini-trial probing.
- Installed `seqkit`, `bbmap`/BBTools `reformat.sh`, and `pigz` to provide alternate FASTQ/gzip validation and repair options after repeated gzip CRC failures on Stage 1 generated outputs.
- Downloaded Broad Picard `3.4.0` jar to `/home/rayzw/tools/picard/picard.jar`.
- Started Docker Desktop and pulled `google/deepvariant:1.6.0`.
- Updated `config.env` so `DOCKER_BIN=docker.exe`.
