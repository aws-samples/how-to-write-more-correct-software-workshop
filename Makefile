
test_complete: verify_complete

test_docs:


txm_docs:
	# Run all the tests in the markdown
	# This verifies that tested code block
	# do exist in ./exercises/complete/src/AwsKmsArnParsing.dfy
	npx txm ./instructions/steps.md

TMPDIR=$(mktemp -d)
asdf_docs:
	# This tests the other direction.
	# That every line in exercises/complete/src/AwsKmsArnParsing.dfy
	# exists somehwere in ./instructions/steps.md
	bash -c 'comm -23 \
		<\(sort exercises/complete/src/AwsKmsArnParsing.dfy | uniq\) \
		<\(sort ./instructions/steps.md | uniq\)'

verify_complete:
	dafny /compile:0 exercises/complete/src/Index.dfy

# compile: | compile_cs compile_go compile_java

# compile_fail: | compile_js compile_py compile_cpp

# compile_cs:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:cs \
# 	--args \
# 	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	arn:aws-cn:kms:us-west-2:658956600833:b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"
# compile_go:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:go \
# 	--args \
# 	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"
# compile_js:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:js \
# 	--args \
# 	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"
# compile_java:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:java \
# 	--args \
# 	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"
# compile_py:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:py \
# 	--args \
# 	arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"
# compile_cpp:
# 	dafny \
# 	src/Index.dfy \
# 	/compile:3 \
# 	/compileTarget:cpp \
# 	--args \
# 	--args arn:aws-cn:kms:us-west-2:658956600833:key/b3537ef1-d8dc-4780-9f5a-55776cbb2f7f \
# 	asdf \
# 	"alias\ryan"

# duvet_report:
# 	duvet \
# 		report \
# 		--ci \
# 		--spec-pattern "aws-kms-key-arn/**/*.toml" \
#   	--require-citations true \
#   	--require-tests true \
# 		--no-cargo \
# 		--html compliance_report.html \
# 		--source-pattern src/*.dfy

# duvet_extract:
# 	duvet extract aws-kms-key-arn.txt 