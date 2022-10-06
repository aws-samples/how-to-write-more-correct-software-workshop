
verify:
	dafny -compile:0 -trace src/*.dfy

execute: | execute_cs execute_go execute_java

execute_fail: | execute_js execute_py execute_cpp

execute_cs:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:cs \
	--args \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	arn:aws-cn:kms:us-west-2:658956600833:b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_go:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:go \
	--args \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_js:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:js \
	--args \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_java:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:java \
	--args \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_py:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:py \
	--args \
	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
	1234abcd-12ab-34cd-56ef-1234567890ab \
	"alias\ryans-key"
execute_cpp:
	dafny \
	src/Index.dfy \
	/compile:3 \
	/compileTarget:cpp \
	--args \
	--args arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
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

# Invoked as part of the containter set-up, so doesn't need to be part of "all"
install_dependencies:
	npm install bignumber.js
