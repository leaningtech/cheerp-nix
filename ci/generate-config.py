#!/usr/bin/env nix
#! nix shell nixpkgs#nix-eval-jobs nixpkgs#python3 --command python3

from __future__ import annotations
import json
from dataclasses import dataclass
from typing import List, Dict
import subprocess


@dataclass
class Derivation:
    name: str
    drv: str
    deps: List[Derivation]

def generate_circleci_job(drv: Derivation) -> Dict:
    job = {
        "docker": [{"image": "nixos/nix:latest"}],
        "resource_class": "large",
        "steps": [
            "checkout",
            {
                "run": {
                    "name": "Configure Nix",
                    "command": """
cat \\<< 'EOF' > /etc/nix/nix.conf
  cores = 4
  experimental-features = nix-command flakes ca-derivations
  max-jobs = 2
  sandbox = false
  sandbox-fallback = true
  system-features = nixos-test benchmark big-parallel kvm
  substituters = https://nix.leaningtech.com/cheerp https://cache.nixos.org/
  trusted-public-keys = cheerp:WtaH6hNyE1jx3KqrDkTqHfub4qEBhJWZwiIuPAPqF44= lt:990XBPGBQWHGyzpLno3a5vfWo5G8O+0qlxRmrvbOQVQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  trusted-users = root circleci
EOF
nix run nixpkgs#attic-client -- login lt 'https://nix.leaningtech.com' ${ATTIC_TOKEN}
""",
                }
            },
            {
                "run": {
                    "name": f"Build {drv.name}",
                    "command": f"""
nix-store --add-root result --realize {drv.drv}
"""
                }
            },
            {
                "run": {
                    "name": f"Upload to cache",
                    "command": f"""
nix run nixpkgs#attic-client push lt:cheerp result*
"""
                }
            },
        ]
    }
    return job


def generate_circleci_config(drvs: Dict[str, Derivation]) -> Dict:
    jobs = {}
    workflow_jobs = []

    # Generate jobs for each package
    for drv in drvs.values():
        jobs[drv.name] = generate_circleci_job(drv)

        job_config: Dict = {drv.name:{}}
        if drv.deps:
            job_config[drv.name]["requires"] = [ dep.name for dep in drv.deps]

        workflow_jobs.append(job_config)

    config = {
        "version": 2.1,
        "jobs": jobs,
        "workflows": {
            "build-all": {
                "jobs": workflow_jobs
            }
        }
    }

    return config

def get_derivations() -> List[Dict]:
    result = subprocess.run(
               ["nix-eval-jobs", "-E", "(import ./default.nix{}).ci.release", "--gc-roots-dir", ".", "--workers", "4", "--max-memory-size", "2G", "--verbose", "--log-format", "raw"],
               stdout=subprocess.PIPE,
               text=True,
               check=True
           )
    items = []
    for line in result.stdout.strip().split('\n'):
        items.append(json.loads(line))
    return items

def get_all_deps(drv: str) -> List[str]:
    result = subprocess.run(
               ["nix-store", "--query", "--requisites", drv],
               capture_output=True,
               text=True,
               check=True
           )
    return result.stdout.strip().split('\n')

def load_derivations() -> Dict[str, Derivation]:
    items = get_derivations()

    drvs = { i["attr"]:Derivation(name=i["attr"], drv=i["drvPath"], deps=[]) for i in items }
    drvMap = { i["drvPath"]:drvs[i["attr"]] for i in items}
    for i in items:
        v = drvs[i["attr"]]
        v.deps = [ drvMap[d] for d in get_all_deps(i["drvPath"]) if d in drvMap and d != v.drv]

    return drvs

def prune_graph(g: Dict[str, Derivation]) -> Dict[str, Derivation]:
    pruned = {k:Derivation(name=v.name, drv=v.drv, deps=[]) for (k,v) in g.items()}
    for cur in g.keys():
        for dx in g[cur].deps:
            dx_needed = True
            for dy in g[cur].deps:
                if dx in dy.deps:
                    dx_needed = False
                    break
            if dx_needed:
                pruned[cur].deps.append(dx)
    return pruned

drvs = load_derivations()
drvs = prune_graph(drvs)
config = generate_circleci_config(drvs)
print(json.dumps(config, indent=2))
