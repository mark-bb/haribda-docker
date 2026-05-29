# haribda-docker
Haribda in a systemd image
## Introduction
Whatever systemd-based application can be relatively easily installed with this project.  
This project consists of installing Haribda, openssh server, postfix(commented out actually, but it's here just for demo).  
## Building the image
Here is the `cfg` directory content to understand, how the project can be adjusted for any application.
```
$ tree cfg/
cfg/
├── configs_restore.sh
├── configs_save.sh
├── install.d
│   ├── 50-openssh.sh
│   ├── 60-postfix.sh
│   └── 70-haribda.sh
├── install.sh
├── startup.d
│   ├── haribda.sh
│   └── ssh.sh
├── startup.sh
├── utils.d
│   └── haribda.sh
└── utils.sh
```
The `rebuild.sh` script is an example of building an image.  
You provide a base image name (like `-b ubuntu:22.04` or `-b redhat/ubi10`) & a secret file (with `-s` to set some variables, optionally).  
It builds an image with the `haribda/haribda-${IMAGE_SUFFIX?}` name, where `${IMAGE_SUFFIX?}` is derived from the base image name (like `ubuntu` or `redhat`).

The `install.sh` script is the main build script inside an image. It does the following sequentially:
- installs some additional packages, if you provided their names via secrets / env vars optionally
- installs systemd & some additional useful packages
- runs all executable scripts in `install.d`
- runs the `configs_save.sh` script which makes a copy of all your files & directories specified in the `install.d` scripts (by adding the corresponding names to a special text file, see the examples); these files & directories are supposed to be copied to the corresponding mounts provided during the run-time once
- creates a special `startup.service` unit running the `startup.sh` script; this unit will run once before all others to configure your applications (via executable scripts in `startup.d`)
## Running containers
The `run.sh` script is an example of running a container.  
It accepts the same `-b` parameter as for `rebuild.sh`, but just to derive the corresponding image. The container name is always `haribda`.  

The `startup.sh` script is the main startup script inside a container. The `startup.service` systemd unit runs it, which is supposed to run before starting all other user systemd units. So, there is an ability to make whatever configuration changes beforehand.  
The script does the following sequentially:
- runs the `configs_restore.sh` script which copies saved files and directories saved at the setup stage to the correspoinding mounted ones restoring their original OS permissions and modes, if the correspoinding target is empty (directory) or hase zero size (standalone file)
- runs all the executables found in the `startup.d` directory
