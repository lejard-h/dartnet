# Dartnet
Configurable http server in dart.

## Install

`pub global activate dartnet`

### Usage
`dartnet`

or

`pub run dartnet:dartnet`

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

log_file: "dartnet.log" #default: falsedartnet.log

list_directory: false #default: false

redirections: #redirection when error happen
    #404: error.html
    #500: error.html
    default: index.html
    
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