workflow "Build and Deploy" {
  on = "push"
  resolves = ["List Public IP"]
}

# Build

action "Build Docker image" {
  uses = "actions/docker/cli@master"
  args = ["build", "-t", "aws-example", "."]
}

# Deploy Filter
action "Deploy branch filter" {
  needs = ["Push image to ECR"]
  uses = "actions/bin/filter@master"
  args = "branch master"
}

# AWS

action "Login to ECR" {
  uses = "actions/aws/cli@master"
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
  env = {
    AWS_DEFAULT_REGION = "us-west-2"
  }
  args = "ecr get-login --no-include-email --region $AWS_DEFAULT_REGION | sh"
}

action "Tag image for ECR" {
  needs = ["Build Docker image"]
  uses = "actions/docker/tag@master"
  env = {
    IMAGE_NAME = "aws-example"
    CONTAINER_REGISTRY_PATH = "377117578606.dkr.ecr.us-west-2.amazonaws.com"

    # Build

    # AWS
  }
  args = ["$IMAGE_NAME", "$CONTAINER_REGISTRY_PATH/$IMAGE_NAME"]
}

action "Push image to ECR" {
  needs = ["Login to ECR", "Tag image for ECR"]
  uses = "actions/docker/cli@master"
  env = {
    IMAGE_NAME = "aws-example"
    CONTAINER_REGISTRY_PATH = "377117578606.dkr.ecr.us-west-2.amazonaws.com"

    # Build

    # AWS
  }
  args = ["push", "$CONTAINER_REGISTRY_PATH/$IMAGE_NAME"]
}

action "Store Kube Credentials" {
  needs = ["Push image to ECR"]
  uses = "actions/aws/kubectl@master"
  secrets = ["KUBE_CONFIG_DATA"]
}

action "Configure Kube Credentials" {
  needs = ["Login to ECR"]
  uses = "actions/aws/cli@master"
  env = {
    CLUSTER_NAME = "ikeike443-cluster-2"
    AWS_DEFAULT_REGION = "us-west-2"
  }
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
  args = "eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_DEFAULT_REGION"
}

# Example Local Action to use `aws-iam-authenticator`
action "Deploy to EKS" {
  needs = ["Store Kube Credentials", "Deploy branch filter"]
  # ["Configure Kube Credentials"]
  uses = "./.github/actions/eks-kubectl"
  runs = "sh -l -c"
  args = ["SHORT_REF=$(echo $GITHUB_SHA | head -c7) && cat $GITHUB_WORKSPACE/config.yml | sed 's/TAG/'\"$SHORT_REF\"'/' | kubectl apply -f - "]
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
}

action "Verify EKS deployment" {
  needs = [
    "Push image to ECR",
    "Deploy to EKS",
  ]
  # :point_down: use this for self-contained kubectl config credentials 
  #uses = "docker://gcr.io/cloud-builders/kubectl"
  uses = "./.github/actions/eks-kubectl"
  args = ["rollout status deployment/aws-example-octodex"]
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
}

action "List Public IP" {
  needs = "Verify EKS deployment"
  uses = "./.github/actions/eks-kubectl"
  args = ["get services -o wide"]
  secrets = ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
}
