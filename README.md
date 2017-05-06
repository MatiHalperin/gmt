# Git Management Tool (gmt)

A library to clone multiple repos simplerly

## Getting Started

These instructions will get you a copy of the project up and running on your local machine.

### Prerequisites

What things you need to install the software and how to install them

```
$ sudo apt-get install git-core
```

### Installing

A step by step series of examples that tell you have to get it running

Clone this repo

```
$ git clone https://github.com/MatiHalperin/gmt.git
```

And add it to the path by opening .bashrc

```
$ gedit ~/.bashrc
```

And adding at the end of the file

```
source [PATH TO THE CLONED REPO]/gmt.sh
```

Where [PATH TO THE CLONED REPO] is the location of the folder cloned in the first step

## gmt command reference

gmt usage takes the following form:

```
gmt <COMMAND> <OPTIONS>
```

### init

```
$ gmt init -u <URL> [<OPTIONS>]
```
or
```
$ gmt init -f <FILE> [<OPTIONS>]
```

Installs gmt in the current directory. This creates a .gmt/ directory that contains initialized manifest file.

Options:
- `-u`: specify a URL from which to retrieve a manifest repository. The common manifest can be found at `https://android.googlesource.com/platform/manifest`
- `-f`: specify a local file from which to retrieve a manifest repository.
- `-m`: select a manifest file within the repository. If no manifest name is selected, the default is default.xml.
- `-b`: specify a revision, i.e., a particular manifest-branch.

### clone

```
$ gmt clone
```
It will download all the projects missing in the current directory.

### check

```
$ gmt check
```
It will verify if all the projects are present in the current directory, and print the ones that aren't

### sync

```
$ gmt sync
```
Downloads new changes and updates the working files in your local environment. It will synchronize the files for all the projects.

When you run `gmt sync`, this is what happens:
- If the project has already been synchronized once, then `gmt sync` is equivalent to:

    ```
    $ git pull
    ```
After a successful repo sync, the code in specified projects will be up to date with the code in the remote repository.

### reset

```
$ gmt reset
```
It will delete the .gmt/ directory completely
