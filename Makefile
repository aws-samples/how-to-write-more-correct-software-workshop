
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

verify_complete:
	$(MAKE) -C exercises/complete verify

