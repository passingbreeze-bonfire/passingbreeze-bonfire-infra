package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	//	"github.com/stretchr/testify/assert"
)

func TestDevelopmentTerraformExample(t *testing.T) {
	// website::tag::2:: Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// website::tag::1:: Set the path to the Terraform code that will be tested.
		TerraformDir: "..",
	})

	// website::tag::5:: Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// website::tag::3:: Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

}
