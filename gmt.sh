#!/bin/bash

function DownloadFinished()
{
    while read -r line || [[ -n $line ]]
    do
        FOLDER=$(GetValueOfTag "$line" name)

        if ! [ -d "$FOLDER" ]
        then
            echo false
            return
        fi
    done < "$1"

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

    while read -r line || [[ -n $line ]]
    do
        FILE+="$(echo "$line" | tr -s " ")\n"
    done < <(echo -e "$SIMPLIFIEDFILE")

    FILE=$(echo -e "$FILE" | sed 's/<!--/\x0<!--/g;s/-->/-->\x0/g' | grep -zv '^<!--' | tr -d '\0' | grep -v "^\s*$")

    echo "$FILE"
}

function gmt()
{
    if [[ "$1" == "init" ]]; then

        rm -rf .gmtconfig-remotes .gmtconfig-sources

        while read -r line || [[ -n $line ]]
        do
            if [[ "$line" == *"<remote"* ]]; then

                echo "$line" >> .gmtconfig-remotes

            elif [[ "$line" == *"<project"* ]]; then

                echo "$line" >> .gmtconfig-sources

            fi
        done < <(SimplifyFile "$2")

    elif [[ "$1" == "clone" ]]; then

        while [ "$(DownloadFinished .gmtconfig-sources)" == false ]
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
                done < .gmtconfig-remotes

                FOLDER=$(GetValueOfTag "$project" name)
                DESTINATION=$(GetValueOfTag "$project" path)

                if ! [ -d "$DESTINATION" ]
                then
                    if [[ "$project" == *"clone-depth="* ]]
                    then
                        depth=$(GetValueOfTag "$project" clone-depth)
                        ARGUMENTS+="--depth $depth"
                    fi

                    git clone "$URL/$FOLDER" "$DESTINATION" --branch "$BRANCH" "$ARGUMENTS"

                    echo
                fi
            done < .gmtconfig-sources
        done

    elif [[ "$1" == "check" ]]; then

        echo

        while read -r line || [[ -n $line ]]
        do
            FOLDER=$(GetValueOfTag "$line" name)

            if ! [ -d "$FOLDER" ]
            then
                echo El repositorio "$FOLDER" no existe
            fi
        done < .gmtconfig-sources

        echo

    elif [[ "$1" == "sync" ]]; then

        while read -r line || [[ -n $line ]]
        do
            DESTINATION=$(GetValueOfTag "$line" path)

            if [ -d "$DESTINATION" ]
            then
                echo "$DESTINATION:"
                cd "$DESTINATION"
                git pull
                cd - >/dev/null
                echo
            fi
        done < .gmtconfig-sources

    elif [[ "$1" == "reset" ]]; then

        rm -rf .gmtconfig-remotes .gmtconfig-sources

    fi

    for ARGUMENT in "$@"
    do
        if [[ "$ARGUMENT" == "--shutdown" ]]
        then
            systemctl poweroff
        fi
    done
}
