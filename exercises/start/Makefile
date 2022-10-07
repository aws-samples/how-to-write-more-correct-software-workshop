.PHONY: all
all: duvet_extract duvet_ci verify execute 

verify:
	dafny -compile:0 -trace src/*.dfy

execute: | execute_cs execute_go execute_java execute_js execute_py

compile: | compile_cs compile_go compile_js compile_java compile_py

execute_cs: compile_cs
	dotnet \
	runtimes/AwsKmsArn.dll \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	arn:aws-cn:kms:us-west-2:658956600833:b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_go: compile_go
	env \
	GO111MODULE=auto \
	GOPATH=$(PWD)/runtimes/AwsKmsArn-go \
	go run \
	runtimes/AwsKmsArn-go/src/AwsKmsArn.go \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_js: compile_js
	node \
	runtimes/AwsKmsArn.js \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_java: compile_java
	java \
	-cp runtimes/AwsKmsArn-java/DafnyRuntime.jar:runtimes/AwsKmsArn-java \
	AwsKmsArn \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_py: compile_py
	python3 \
	runtimes/AwsKmsArn-py/AwsKmsArn.py \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_cpp: compile_cpp
	runtimes/AwsKmsArn.exe \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"

duvet_report:
	duvet \
		report \
		--ci \
		--spec-pattern "aws-kms-key-arn/**/*.toml" \
  	--require-citations true \
  	--require-tests true \
		--no-cargo \
		--html compliance_report.html \
		--source-pattern src/*.dfy

duvet_extract:
	duvet extract aws-kms-key-arn.txt

duvet_ci:
	duvet \
		report \
		--ci \
		--spec-pattern "aws-kms-key-arn/**/*.toml" \
  	--require-citations true \
  	--require-tests true \
		--no-cargo \
		--source-pattern src/*.dfy

compile_cs:
	dafny build \
	src/Index.dfy \
	--target:cs \
	--output:runtimes/AwsKmsArn
compile_go:
	dafny build \
	src/Index.dfy \
	--target:go \
	--output:runtimes/AwsKmsArn
compile_js:
	dafny build \
	src/Index.dfy \
	--target:js \
	--output:runtimes/AwsKmsArn
compile_java:
	dafny build \
	src/Index.dfy \
	--target:java \
	--output:runtimes/AwsKmsArn
compile_py:
	dafny build \
	src/Index.dfy \
	--target:py \
	--output:runtimes/AwsKmsArn
compile_cpp:
	dafny build \
	src/Index.dfy \
	--target:cpp \
	--output:runtimes/AwsKmsArn

# Invoked as part of the containter set-up, so doesn't need to be part of "all"
install_dependencies:
	npm install bignumber.js
