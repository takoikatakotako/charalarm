#!/bin/bash -eu

cwd=`dirname $0`
cd $cwd/../application
go test -v ./...
