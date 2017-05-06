#!/bin/bash

function DownloadFinished()
{
    while read -r line || [[ -n $line ]]
    do
        if [[ "$line" == *"<project"* ]]
        then
            FOLDER=$(GetValueOfTag "$line" path)

            if [ ! -d "$FOLDER" ]
            then
                echo false
                return
            fi
        fi
    done < <(SimplifyFile "$1")

    echo true
}

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

function gmt()
{
    if [ -d .gmt ]
    then
        while read -r line || [[ -n $line ]]
        do
            if [[ "$line" == *"<remote"* ]]; then

                remotes+="$line\n"

            elif [[ "$line" == *"<project"* ]]; then

                projects+="$line\n"

            fi
        done < <(SimplifyFile .gmt/*.xml)
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

        elif [[ "$2" == "-f" ]]; then

            mkdir .gmt
            cp "$3" .gmt/

        fi

    elif [[ "$1" == "clone" ]]; then

        while [ "$(DownloadFinished .gmt/*.xml)" == false ]
        do
            while read -r project || [[ -n $project ]]
            do
                while read -r remote || [[ -n $remote ]]
                do
                    NAME=$(GetValueOfTag "$remote" name)

                    if [[ "$project" == *"$NAME"* ]]
                    then
                        URL=$(GetValueOfTag "$remote" fetch)

                        if [[ "$project" == *"revision="* ]]
                        then
                            BRANCH=$(GetValueOfTag "$project" revision)
                        else
                            BRANCH=$(GetValueOfTag "$remote" revision | cut -d '/' -f 3)
                        fi
                    fi
                done <<< "$remotes"

                FOLDER=$(GetValueOfTag "$project" name)
                DESTINATION=$(GetValueOfTag "$project" path)

                if ! [ -d "$DESTINATION" ]
                then
                    depth=$(GetValueOfTag "$project" clone-depth)

                    if [ -n "$depth" ]
                    then
                        ARGUMENTS="--depth $depth"
                    fi

                    COMMAND=$(echo git clone --branch "$BRANCH" "$ARGUMENTS" "$URL/$FOLDER" "$DESTINATION" | tr -s " ")

                    eval "$COMMAND"

                    if [ -n "$ARGUMENTS" ]
                    then
                        unset -v ARGUMENTS
                    fi

                    echo
                fi
            done <<< "$projects"
        done

    elif [[ "$1" == "sync" ]]; then

        while read -r project || [[ -n $project ]]
        do
            while read -r remote || [[ -n $remote ]]
            do
                NAME=$(GetValueOfTag "$remote" name)

                if [[ "$project" == *"$NAME"* ]]
                then
                    DESTINATION=$(GetValueOfTag "$project" path)

                    if [ -d "$DESTINATION" ]
                    then
                        echo "$DESTINATION:"

                        if [[ "$remote" == *"refs/tags/"* ]]
                        then
                            TAG=$(GetValueOfTag "$remote" revision | cut -d '/' -f 3)

                            if [[ $(git -C "$DESTINATION" describe --tags) != "$TAG" ]]
                            then
                                git -C "$DESTINATION" pull
                                git -C "$DESTINATION" checkout "$TAG"
                            fi
                        else
                            git -C "$DESTINATION" pull
                        fi

                        echo
                    fi
                fi
            done <<< "$remotes"
        done <<< "$projects"

    elif [[ "$1" == "reset" ]]; then

        rm -rf .gmt

    fi

    for ARGUMENT in "$@"
    do
        if [[ "$ARGUMENT" == "--shutdown" ]]
        then
            systemctl poweroff
        fi
    done
}
