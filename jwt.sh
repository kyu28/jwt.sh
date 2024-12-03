#!/bin/sh
#
# jwt.sh - encode, decode and verify JWT
# dependencies: openssl base64 xxd sed

base64url_encode() {
    base64 -w0 | sed 's/+/-/g' | sed 's/\//_/g' | sed 's/=//g'
}

base64_padding() {
    read chars
    printf $chars
    paddings=$(( (8 - (${#chars} * 6) % 8) % 8 ))
    while [ $paddings -gt 0 ]; do
        printf "="
        paddings=$(( (8 + $paddings - 6) % 8 ))
    done
}

base64url_decode() {
    base64_padding | sed 's/_/\//g' | sed 's/-/+/g' | base64 -d
}

to_hex() {
    printf "$1" | xxd -p
}

hs() {
    openssl dgst -sha$1 -mac HMAC -macopt "hexkey:$2" -binary
}

rs_sign() {
    openssl dgst -sha$1 -sign "$2" -binary
}

rs_verify() {
    openssl dgst -sha$1 -verify "$2" -signature "$3"
}

jwt_encode() {
    secret=$3
    header=$(printf '{"alg":"'$1'","typ":"JWT"}' | base64url_encode)
    payload=$(printf "%s" "$2" | sed 's/ //g' | base64url_encode)
    if [ "$1" = "none" ]; then
        echo "$header.$payload."
        return
    fi
    [ -z "$secret" ] && echo "error: secret is required" && exit 1
    method=${1%???}
    bits=${1#$method}
    case "$method" in
    HS)
        signature=$(printf "%s" "$header.$payload" | hs $bits $(to_hex "$secret" | base64url_encode));;
    RS)
        signature=$(printf "%s" "$header.$payload" | rs_sign $bits "$secret" | base64url_encode);;
    *)
        echo "error: unsupported alg \"$1\""
        exit 1;;
    esac
    echo "$header.$payload.$signature"
}

jwt_decode() {
    secret=$2
    header=${1%%.*}
    payload=${1%.*}
    payload=${payload#*.}
    signature=${1##*.}
    echo HEADER:
    echo $header | base64url_decode
    echo
    echo PAYLOAD:
    echo $payload | base64url_decode
    echo
    alg=$(printf $header | base64url_decode |
        sed -n -e 's/.*"alg": *"\([a-zA-Z0-9]*\)".*/\1/p')
    if [ "$alg" = "none" ] || [ -z "$secret" ]; then
        echo "Signature Verify Skipped"
        return
    fi
    method=${alg%???}
    bits=${alg#$method}
    case "$method" in
    HS)
        calc_sign=$(printf "$header.$payload" | hs $bits $(to_hex "$secret") | base64url_encode);;
    RS)
        if [ "$secret" = "--pub" ]; then
            tmp_file=".tmp.sign"
            secret=$3
            [ -f "$tmp_file" ] && echo "error: tmp file $tmp_file exists" && exit 1
            printf "$signature" | base64url_decode > $tmp_file
            printf "$header.$payload" | rs_verify $bits "$secret" "$tmp_file" > /dev/null 2>&1
            ret=$?
            if [ "$ret" -eq 0 ]; then
                echo "Signature Verified"
            else
                echo "Invalid Signature"
            fi
            rm "$tmp_file"
            return $ret
        else
            calc_sign=$(printf "$header.$payload" | rs_sign $bits "$secret" | base64url_encode)
        fi;;
    *)
        echo "error: unsupported alg \"$alg\"";;
    esac
    if [ "$calc_sign" = "$signature" ]; then
        echo "Signature Verified"
        return 0
    else
        echo "Invalid Signature"
        return 1
    fi
}

usage() {
    cat << EOF
Usage:
$0 enc [alg] [payload] [secret]
$0 dec [token] [secret]
$0 dec [token] --pub [pubkey]
alg: none HS256 HS384 HS512 RS256 RS384 RS512
secret: string when using HS256, HS384, HS512
        private key path when using RS256, RS384, RS512
        this field will be omitted when using none alg       

Example:
$0 enc HS256 '{"hello":"world"}' 'i_am_a_secret'
$0 enc RS384 '{"hello":"world"}' '/path/to/private_key.pem'
$0 enc none '{"hello":"world"}'
$0 dec eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrIjoidiJ9.\
euqFBgx-u-yFgwYu8w2-e5_SFyZjMcVr61_O5rewDw8 'i_am_a_secret'
$0 dec eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJoZWxsbyI6IndvcmxkIn0.
EOF
}

case "$1" in
enc)
    shift
    jwt_encode "$@"
    ;;
dec)
    shift
    jwt_decode "$@"
    ;;
*)
    usage;;
esac
