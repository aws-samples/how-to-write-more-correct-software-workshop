
.PHONY: all
all: txm_steps steps_are_complete specifications_are_the_same makefiles_are_the_same verify_complete assert_unchanged

txm_steps:
	# Run all the tests in the markdown
	# This verifies that tested code block
	# do exist in ./exercises/complete/src/AwsKmsArnParsing.dfy
	npx txm ./instructions/steps.md

steps_are_complete:
	# This tests the other direction.
	# That every line in exercises/complete/src/AwsKmsArnParsing.dfy
	# exists somehwere in ./instructions/steps.md
	./util/"steps are complete.sh"

specifications_are_the_same:
	cmp exercises/complete/aws-kms-key-arn.txt exercises/start/aws-kms-key-arn.txt

makefiles_are_the_same:
	cmp exercises/complete/Makefile exercises/start/Makefile

verify_complete:
	$(MAKE) -C exercises/complete

assert_unchanged:
	git diff --exit-code || (echo "ERROR: Source changes detected (see above). Build the reference manual locally and commit these changes." && exit 1)
