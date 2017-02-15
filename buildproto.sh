#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/proto

for file in `ls`
do
	if [ -f $file ]; then
		extension="${file##*.}"
		if [ "proto" = $extension ]; then
			echo building $file
			`../protoc --plugin=protoc-gen-lua="../plugin/protoc-gen-lua" --lua_out=../output $file`
		fi
	fi
done
echo done
