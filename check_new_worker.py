from ast import mod
import os
import shutil
import sys
import subprocess
from turtle import mode
from loguru import logger

from repository_utils.repository_utils import get_worker_installed_version, get_newer_release_version, download_and_extract_new_release

token = os.environ.get("GITHUB_TOKEN", None)
repository = os.environ.get("WORKERS_REPOSITORY", None)
model_mode = os.environ.get("MODEL_MODE", None)
service_name = ""
result = False

if token is None:
    logger.error("Error: no github token provided. Exiting.")
    exit(1)
elif repository is None:
    logger.error("Error: no repository provided. Exiting.")
    exit(1)
elif model_mode is None:
    logger.error("Error: model_mode is not configured. Exiting.")
    exit(1)
else:
    if model_mode == "LT":
        install_path = os.environ.get("LT_INSTALL_PATH", None)
        if install_path is None:
            logger.error("Error: LT_install_path is not configured. Exiting.")
            exit(1)
        service_name = "worker_long_term"
    elif model_mode == "ST_SOLVER" or model_mode =="ST_SCHEDULER":
        install_path = os.environ.get("ST_INSTALL_PATH", None)
        if install_path is None:
            logger.error("Error: ST_install_path is not configured. Exiting.")
            exit(1)
        if model_mode == "ST_SOLVER":
            service_name = "worker_short_term_solver"
        if model_mode == "ST_SCHEDULER":
            service_name = "worker_short_term_scheduler"
    else:
        logger.error("Error: model_mode is not valid. Exiting.")
        exit(1)
    install_path = os.path.expanduser(install_path)
    existing_version = get_worker_installed_version(os.path.join(install_path, "installed_version.txt"))
    new_version = get_newer_release_version(token, repository, existing_version)
    if new_version is not None:
        result = download_and_extract_new_release(token, repository,new_version, install_path)
    if result:
        logger.info("version updated. Stopping celery")
        subprocess.run(["pkill", "service_name"]) 