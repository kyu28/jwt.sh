# jwt.sh
encode, decode and verify JWT

## Supported algorithm
```
none
HS256
HS384
HS512
RS256
RS384
RS512
```

## Dependency
```
openssl
base64
xxd
sed
```
Debian
```sh
# vim for xxd
apt install openssl sed vim
```
Alpine
```sh
# base64, xxd, sed are included in busybox
apk add openssl-misc
```

## Usage
```sh
jwt.sh enc [alg] [payload] [secret]
jwt.sh dec [token] [secret]
jwt.sh dec [token] --pub [pubkey]

alg:    none HS256 HS384 HS512 RS256 RS384 RS512
secret: string when using HS256, HS384, HS512
        private key path when using RS256, RS384, RS512
        this field will be omitted when using none alg
pubkey: public key path when using RS256, RS384, RS512
```
### Encode and sign a JWT using HS256, HS384, HS512
```sh
jwt.sh enc '{"hello": "world"}' 'i_am_a_secret_key'
```

### Encode and sign a JWT using RS256, RS384, RS512
```sh
jwt.sh enc '{"hello": "world"}' '/path/to/rsa/private_key.pem'
```

### Decode and verify a JWT
```sh
# HS256, HS384, HS512
jwt.sh dec 'eyJhbGciOiJIUzI1NiJ9.eyJrIjoidiJ9.oLV5ZIHTfktQGg8nBYBo4XkDu5xwuri10tC7fa7QYmk' 'a_secret'
# RS256, RS384, RS512 with private key
jwt.sh dec [token] '/path/to/rsa/private_key.pem'
# RS256, RS384, RS512 with public key
jwt.sh dec [token] --pub '/path/to/rsa/public_key.pem'
```

### Decode a JWT without verifying
```sh
# alg none is supported
jwt.sh dec eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJoZWxsbyI6IndvcmxkIn0.
jwt.sh dec 'eyJhbGciOiJIUzI1NiJ9.eyJrIjoidiJ9.oLV5ZIHTfktQGg8nBYBo4XkDu5xwuri10tC7fa7QYmk'
```
