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
try:
    result = subprocess.run(docker_cmd, check=True, capture_output=True, text=True)
    print("✅ Output:")
    print(result.stdout)
except subprocess.CalledProcessError as e:
    print("❌ Error:")
    print(e.stderr)
