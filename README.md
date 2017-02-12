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
server:
  address: "0.0.0.0"
  port: 1337
  root_directory: build
```

This will serve all file under the 'build' directory.

### Complete

```yaml
server:
  address: "0.0.0.0"
  port: 1337
  root_directory: build
  multithread: false
  redirections:
    #404: error.html
    #500: error.html
    default: index.html #this will redirect every error to the index.html file
  log: info
  log_file: "dartnet.log"
  list_directory: false
```

## Run example

```
cd example
dartnet
```