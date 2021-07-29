---
title: "Entropy and AWS"
date: "2021-07-29T01:44:18Z"
tags: [aws, programming]
---

Something I've been thinking about recently is how to ensure sufficient randomization across clusters of EC2 resources given hundreds of virtual machines.
The entropy that exists at the launch point of a new EC2 resource from an AMI could be such that `/dev/random` causes more duplicates from PRNGs across the cluster over time.

I'm not convinced yet that this is should be a huge concern, considering there should be sufficient entropy available across the host server blades and exposed via the hypervisor AWS uses.
At the same time, I couldn't find any documentation from AWS to clarify this, so I figured I'd consider what would need to change in order to avoid the problem entirely.

There are surprisingly few changes necessary in order to solve this problem.
AWS KMS provides a piece of functionality to generate cryptographically secure random numbers, so it can be used to solve this problem rather quickly from EC2 user data.

The first step is to create a new IAM policy and attach it to the required role used for IAM on the cluster.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRandomGeneration",
            "Effect": "Allow",
            "Action": ["kms:GenerateRandom"],
            "Resource": "*"
        }
    ]
}
```

Following that, at least for my use-cases, the EC2 user data can be updated with a call to the AWS CLI tool.

```
aws kms generate-random --number-of-bytes 256 \
        --output text --query Plaintext \
    | base64 --decode > /dev/random
```

This won't unblock `/dev/random` for reading until the system gathers enough entropy, but it does at least ensure different data is injected into each EC2 resource.
It's a neat little piece of code though that doesn't add much overhead to the boot process.
