upload() {
    SOURCE=$1
    TARGET=$2
    TYPE=$3

    echo "Authentifiziere bei B2..."
    b2_auth_json=$(curl -s -u $B2_ACCOUNT_ID:$B2_APPLICATION_KEY https://api.backblazeb2.com/b2api/v2/b2_authorize_account)
    b2_token=$(echo $b2_auth_json | jq --raw-output .authorizationToken)
    b2_api_url=$(echo $b2_auth_json | jq --raw-output .apiUrl)

    echo "Generiere Upload-URL..."
    b2_upload_url_json=$(curl -s -H "Authorization: $b2_token" -d '{"bucketId": "'"$B2_BUCKET_ID"'"}' "$b2_api_url/b2api/v2/b2_get_upload_url")
    b2_upload_url=$(echo $b2_upload_url_json | jq --raw-output .uploadUrl)
    b2_upload_token=$(echo $b2_upload_url_json | jq --raw-output .authorizationToken)

    SHA1=$(openssl dgst -sha1 "$SOURCE" | awk '{print $2;}')

    echo "Datei wird hochgeladen..."
    curl \
        -s \
        --progress-bar \
        -H "Authorization: $b2_upload_token" \
        -H "X-Bz-File-Name: $TARGET" \
        -H "Content-Type: $TYPE" \
        -H "X-Bz-Content-Sha1: $SHA1" \
        -H "X-Bz-Info-Author: unknown" \
        --data-binary "@$SOURCE" \
        $b2_upload_url \
        > /dev/null
}

select_file() {
    dir=$(pwd)
    title=${1:-"Wähle eine Datei"}

    filename="."
    while [ -d "$filename" ]
    do
        cd $filename
        files=".. Ordner"
        for f in *; do
            files="$files \"$f\""
            if [ -d $f]
            then
                files="$files Ordner"
            else
                files="$files Datei"
            fi
            
        done

        exec 3>&2
        filename=$(eval "dialog --nocancel --menu \"$title\" 0 60 0 $files" 2>&1 1>&3)
        exit_status=$?
        exec 3>&-

        if [ $exit_status -eq 255 ]
        then 
            clear
            exit 1
        fi
    done
    path="$(pwd)/$filename"
    cd "$dir"
    echo $path
} 