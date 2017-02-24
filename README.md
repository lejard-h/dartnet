# Dartnet
Configurable http server in dart.

- [ ] For production server
- [ ] For dev server (`pub serve` proxy)

## Install

`pub global activate dartnet`

### Usage
`dartnet`

or

`pub run dartnet:dartnet`

### Commands

```
Usage 'dartnet' :
        -c, --config    (defaults to "dartnet.yaml")
        -h, --help      

COMMANDS:
        init    Create config file with default value.
                -f, --filename    (defaults to "dartnet.yaml")
        dockerize       Create a Dockerfile from the Dartnet config file
                -f, --filename    (defaults to "dartnet.yaml")

```

## Configuration

Dartnet use a configuration file (default: 'dartnet.yaml')

### Basic
```yaml
address: "0.0.0.0"
port: 1337
root_directory: build
```

This will serve all file under the 'build' directory.

### Complete

```yaml
address: "0.0.0.0" #default: 0.0.0.0

port: 1337 #default: 8080

root_directory: web #default: build

multithread: true #default: true

log: info #default: info

log_file: "dartnet.log" #default: dartnet.log

list_directory: false #default: false

gzip: true #default: true

redirections:
  path:
    /: "index.html" #default behavior
    /redirect: "https://www.google.com"
    /**: "index.html"
  404: error.html
    
https:
  cert: ssl/cert.pem
  key: ssl/key.pem
  password_key: "dartnet"
```

## Run example

```
cd example
dartnet
```