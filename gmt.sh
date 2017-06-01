#!/bin/bash

function GetValueOfTag()
{
    PARTS=$(echo "$1" | tr " " "\n")
    
    for VALUE in $PARTS
    do
        if [[ "$VALUE" == *"$2"* ]]
        then
            FOLDER=$(echo "$VALUE" | cut -d '=' -f 2 | cut -d '"' -f 2)
            echo "$FOLDER"
        fi
    done
}

function SimplifyFile()
{
    while read -r line || [[ -n $line ]]
    do
        if [[ "$line" == *"<"* && "$line" == *"/>"* || "$line" == *"<"* && "$line" == *">"* ]]; then

            SIMPLIFIEDFILE+="$line\n"

        elif [[ "$line" == *"/>"* ]]; then

            SIMPLIFIEDFILE+=" $line\n"

        else

            SIMPLIFIEDFILE+=" $line"

        fi
    done < "$1"

    echo -e "$SIMPLIFIEDFILE" | tr -s " " | sed 's/<!--/\x0<!--/g;s/-->/-->\x0/g' | grep -zv '^<!--' | tr -d '\0' | grep -v "^\s*$"
}

function clone_project()
{
    PROJECT=$1
    REMOTE=$2

    URL=$(GetValueOfTag "$REMOTE" fetch)

    REPOSITORY=$(GetValueOfTag "$PROJECT" name)
    DESTINATION=$(GetValueOfTag "$PROJECT" path)

    if [[ "$PROJECT" == *"revision="* ]]
    then
        BRANCH=$(GetValueOfTag "$PROJECT" revision)
    else
        BRANCH=$(GetValueOfTag "$REMOTE" revision | cut -d '/' -f 3)
    fi

    DEPTH=$(GetValueOfTag "$PROJECT" clone-depth)

    if [ -n "$DEPTH" ]
    then
        ARGUMENTS+="--depth $DEPTH"
    fi

    COMMAND=$(echo git clone --branch "$BRANCH" "$ARGUMENTS" "$URL/$REPOSITORY" "$DESTINATION" | tr -s " ")

    while [ ! -d "$DESTINATION" ]
    do
        eval "$COMMAND"
    done

    if [ -n "$ARGUMENTS" ]
    then
        unset -v ARGUMENTS
    fi
}

function check_project()
{
    FOLDER=$(GetValueOfTag "$1" path)

    if [ ! -d "$FOLDER" ]
    then
        echo El repositorio "$FOLDER" no existe
    fi
}

function sync_project()
{
    PROJECT=$1
    REMOTE=$2

    FOLDER=$(GetValueOfTag "$PROJECT" path)

    if [ -d "$DESTINATION" ]
    then
        echo "$DESTINATION:"

        if [[ "$REMOTE" == *"revision=\"refs/tags/"* ]]
        then
            TAG=$(GetValueOfTag "$REMOTE" revision | cut -d '/' -f 3)

            if [[ $(git -C "$DESTINATION" describe --tags) != "$TAG" ]]
            then
                git -C "$DESTINATION" pull
                git -C "$DESTINATION" checkout "$TAG"
            fi
        else
            URL=$(GetValueOfTag "$REMOTE" fetch)
            REPOSITORY=$(GetValueOfTag "$PROJECT" name)

            if [[ "$PROJECT" == *"revision="* ]]
            then
                BRANCH=$(GetValueOfTag "$PROJECT" revision)
            else
                BRANCH=$(GetValueOfTag "$REMOTE" revision | cut -d '/' -f 3)
            fi

            git -C "$DESTINATION" pull "$URL/$REPOSITORY" "$BRANCH"
        fi
    else
        clone_project "$1"
    fi
}

function gmt()
{
    if [ -d .gmt ]
    then
        rm -rf .gmt/remotes .gmt/projects

        FILE=$(cat .gmt/main_file)

        while read -r line || [[ -n $line ]]
        do
            if [[ "$line" == *"<remote"* ]]; then

                echo "$line" >> .gmt/remotes

            elif [[ "$line" == *"<project"* ]]; then

                echo "$line" >> .gmt/projects

            elif [[ "$line" == *"<default"* ]]; then

                echo "$line" >> .gmt/default_remote

            fi
        done < <(SimplifyFile ".gmt/$FILE")
    fi

    if [[ "$1" == "init" ]]; then

        rm -rf .gmt/

        if [[ "$2" == "-u" ]]; then

            URL=$3

            for (( i=1; i<=$#; i++ ))
            do
                NEXTARGUMENT=$((i+1))

                if [[ "${!i}" == "-b" ]]
                then
                    BRANCH=${!NEXTARGUMENT}
                fi

                if [[ "${!i}" == "-m" ]]
                then
                    MANIFEST=${!NEXTARGUMENT}
                fi
            done

            if [ -z "$MANIFEST" ]
            then
                MANIFEST="default.xml"
            fi

            if [ -n "$BRANCH" ]
            then
                git clone --quiet --branch "$BRANCH" "$URL" .gmt/tmp
            else
                git clone --quiet "$URL" .gmt/tmp
            fi

            cp .gmt/tmp/$MANIFEST .gmt/$MANIFEST

            rm -rf .gmt/tmp

            echo "$MANIFEST" > .gmt/main_file

        elif [[ "$2" == "-f" ]]; then

            mkdir .gmt
            cp "$3" .gmt/
            echo "$3" > .gmt/main_file

        fi

    elif [[ "$1" == "clone" || "$1" == "sync" ]]; then

        while read -r project || [[ -n $project ]]
        do
            while read -r remote || [[ -n $remote ]]
            do
                if [ -z "$(GetValueOfTag "$project" remote)" ]
                then
                    NAME=$(GetValueOfTag "$(cat .gmt/default_remote)" remote)
                else
                    NAME=$(GetValueOfTag "$remote" name)
                fi

                if [[ "$project" == *"remote=\"$NAME\""* ]]
                then
                    if [[ "$1" == "clone" ]]
                    then
                        clone_project "$project" "$remote"
                    else
                        sync_project "$project" "$remote"
                    fi

                    echo
                fi
            done < .gmt/remotes
        done < .gmt/projects

    elif [[ "$1" == "check" ]]; then

        echo

        while read -r project || [[ -n $project ]]
        do
            check_project "$project"
        done < .gmt/projects

        echo

    elif [[ "$1" == "reset" ]]; then

        rm -rf .gmt/

    fi

    for ARGUMENT in "$@"
    do
        if [[ "$ARGUMENT" == "--shutdown" ]]
        then
            systemctl poweroff
        fi
    done
}
