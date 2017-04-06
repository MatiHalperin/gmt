#!/bin/bash

function DownloadFinished()
{
    while read -r line || [[ -n $line ]];
    do
        FOLDER=$(echo "$line" | cut -d'"' -f 2)

        if ! [ -d "$FOLDER" ];
        then
            echo "false"
            return
        fi
    done < "$1"

    echo "true"
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

function gmt()
{
    if [[ "$1" == "init" ]]; then

        rm -rf .gmtconfig-values .gmtconfig-source
        echo "$2;$3" > .gmtconfig-values
        cp "$4" .gmtconfig-source

    elif [[ "$1" == "change-values" ]]; then

        rm -rf .gmtconfig-values
        echo "$2;$3" > .gmtconfig-values

    elif [[ "$1" == "change-source" ]]; then

        rm -rf .gmtconfig-source
        cp "$2" .gmtconfig-source

    elif [[ "$1" == "clone" ]]; then

        while [ "$(DownloadFinished .gmtconfig-source)" = "false" ];
        do
            while read -r line || [[ -n $line ]];
            do
                URL=$(echo "$line" | cut -d';' -f 1)
                BRANCH=$(echo "$line" | cut -d';' -f 2)
            done < .gmtconfig-values

            LINE=

            while read -r line || [[ -n $line ]];
            do

                if [[ "$line" == *"<"* && "$line" != *"/>"* ]]; then

                    unset $LINE
                    LINE="$line"

                elif [[ "$line" == *"/>"* ]]; then

                    LINE+=" $line"

                    FOLDER=$(GetValueOfTag "$LINE" name)
                    DESTINATION=$(GetValueOfTag "$LINE" path)

                    if ! [ -d "$DESTINATION" ]
                    then
                        git clone -b "$BRANCH" "$URL/$FOLDER" "$DESTINATION"
                    fi

                else
                    LINE+=" $line"
                fi

            done < .gmtconfig-source
        done

    elif [[ "$1" == "check" ]]; then

        echo

        while read -r line || [[ -n $line ]];
        do
            FOLDER=$(GetValueOfTag "$line" name)

            if ! [ -d "$FOLDER" ];
            then
                echo El repositorio "$FOLDER" no existe
            fi
        done < .gmtconfig-source

        echo

    elif [[ "$1" == "sync" ]]; then

        while read -r line || [[ -n $line ]];
        do
            DESTINATION=$(GetValueOfTag "$line" path)

            cd $DESTINATION
            git pull
            cd -
            echo
        done < .gmtconfig-source

    elif [[ "$1" == "reset" ]]; then

        rm -rf .gmtconfig-source .gmtconfig-values

    fi

    for ARGUMENT in "$@"
    do
        if [[ "$ARGUMENT" == "--shutdown" ]]
        then
            systemctl poweroff
        fi
    done
}
