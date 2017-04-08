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
$ gedit .bashrc
```

And adding at the end of the file

```
source [PATH TO THE CLONED REPO]/gmt.sh
```

Where [PATH TO THE CLONED REPO] is the location of the folder cloned in the first step

## Commands available

Now that you have gmt installed, the following commands are available from any terminal

### init

You need to specify the the local file with all the repositories

```
$ gmt init [FILE]
```

### clone

You don't need to specify anything. It will clone all the repos that aren't cloned already

```
$ gmt clone
```

### check

It will verify if all the repos are cloned, and tell you the ones that aren't

```
$ gmt check
```

### sync

It will pull all the new commits from the repos and clone the missing ones, if any

```
$ gmt sync
```

### reset

It will delete the config files containing the URL, branch and repos (the file with the repos, not the repos itself)

```
$ gmt reset
```
