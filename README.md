# 🧬 SNPedia Batch Annotator

A powerful and parallelized R-based tool for annotating SNP rsIDs using the [SNPediaR](https://cran.r-project.org/package=SNPediaR) API, packaged in a Docker container for reproducibility and scalability.

---

## 🚀 Features

* Accepts an `input.txt` list of rsIDs (optionally with genotypes).
* Splits input into batches (default: 500 entries per batch).
* Uses parallel processing across 80% of available CPU cores.
* Fetches SNP info, associated conditions, and genotype-based interpretations.
* Saves both per-batch and aggregated results in structured JSON format.

---

## 🐋 Dockerized Execution

Run the R script via Python controller script at `/home/milad/milad/Varient-docker/pyscript/snpedia/vc.py`:

```bash
python3 /home/milad/milad/Varient-docker/pyscript/snpedia/vc.py
```

This Python script constructs and runs the Docker command:
```bash
docker pull cosmos9526/snp_calling:latest
```
```python
import subprocess

local_volume_path = "/home/milad/milad/Varient-docker/pyscript/snpedia"
container_volume_path = "/data"
container_image = "disvar_v1"
r_script_name = "run_snp_batch.R"
conda_env = "r-environment"

docker_cmd = [
    "docker", "run", "--rm",
    "-v", f"{local_volume_path}:{container_volume_path}",
    container_image,
    "bash", "-c",
    f"source activate {conda_env} && Rscript {container_volume_path}/{r_script_name}"
]

subprocess.run(docker_cmd, check=True)
```

---

## 📂 File Structure

```
snpedia/
├── input.txt                 # Your rsID list, one per line or in format: rsID,(GENO)
├── run_snp_batch.R          # Main R script
├── output.json              # Combined output file
├── vc.py                    # Python script to launch Docker container
└── batch_results/           # Folder containing JSON output per batch
```

## 📥 Input Format

Plain text file `input.txt`:

```
rs2476601
rs7025486
rs7025486(A;A)
```

Each line: either just an `rsID` or `rsID,(GENOTYPE)` format.

---

## 📤 Output Format

Each rsID will have:

```json
"rs7025486": {
  "snp_info": [
    ["7025486", "9", "121660124", "plus", "0.2603", "GRCh38", "38.1", "141", "(A;A)", "(A;G)", "(G;G)", "plus", null, null, "DAB2IP", "DAB2IP", null]
  ],
  "conditions": [
    "Smoking", "Stroke", "Abdominal aortic aneurysm", "Aneurysm",
    "Coronary artery disease", "Diabetes", "Heart disease",
    "Intracranial Aneurysm", "Myocardial infarction",
    "Obesity", "Peripheral arterial disease"
  ],
  "genotypes": [
    "rs7025486(A;A)", "rs7025486(A;G)", "rs7025486(G;G)"
  ],
  "genotype_info": [
    ["7025486", "A", "A", "Bad", "1.6", "slight (1.4x) increase in risk for abdominal aortic aneurysm and other vascular disorders"],
    ["7025486", "A", "G", "Bad", "1.4", "slight (1.2x) increase in risk for abdominal aortic aneurysm and some vascular disorders"],
    ["7025486", "G", "G", "Good", "0", "common/normal"]
  ]
}
```

---

## ⚙️ Dependencies

Inside the Docker image or Conda env:

* R + packages: `SNPediaR`, `jsonlite`, `parallel`
* Internet access to fetch data from SNPedia

---

## 📈 Performance Tips

* Modify `batch_size`, `api_delay`, or `num_cores` in the R script for optimal load.
* If errors occur due to API rate limits, increase `api_delay`.

---

## ❤️ Author

Milad Bagheri — Powered by Open Source and caffeine ☕

---

## 📄 License

MIT License
