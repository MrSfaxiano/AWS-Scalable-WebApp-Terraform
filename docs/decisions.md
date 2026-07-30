# Design Decisions & Incident Log

This document records the deliberate architectural tradeoffs made in this project, along with real debugging incidents encountered during the build. It's kept separate from the README so the README stays focused on "how to use this," while this file captures "why it's built this way" — the kind of reasoning that matters in a design review or an interview.

---

## Deliberate cost/scope tradeoffs

### Single NAT Gateway instead of one per AZ
**Decision:** The VPC module deploys one NAT Gateway (in the first public subnet) rather than one per Availability Zone.

**Why:** A textbook highly-available design places a NAT Gateway in every AZ so that an AZ failure never takes down outbound internet access for the private subnet in another AZ. Each NAT Gateway costs roughly $30–35/month even when idle, so a 2-AZ setup would double that fixed cost.

**Tradeoff accepted:** If the AZ hosting the single NAT Gateway fails, private subnet instances in the *other* AZ would lose outbound internet access (patching, SSM connectivity, etc.) even though the instances themselves are still healthy. For a portfolio/learning project this is an acceptable, explicitly-understood cut corner — not an oversight. In a real production system handling real traffic, one NAT Gateway per AZ would be the correct call.

### `skip_final_snapshot = true` on RDS
**Decision:** The RDS instance is configured to skip creating a final snapshot on deletion.

**Why:** This project is destroyed and recreated repeatedly between work sessions to control cost. Requiring a final snapshot on every `terraform destroy` would leave orphaned snapshots accumulating (each with its own small storage cost) and slow down teardown. In real production, `skip_final_snapshot = false` (the safer default) would almost always be correct — you want a recovery point before deleting a production database.

### RDS instance class and Multi-AZ cost awareness
**Decision:** `db.t3.micro` with `multi_az = true`.

**Why it matters:** Multi-AZ is *not* covered by the AWS free tier (only single-AZ `db.t2.micro`/`db.t3.micro` is), so this is one of the more expensive pieces of the stack while running. It was kept on deliberately, since Multi-AZ failover is one of the core learning objectives of this project (Chapter 9 — "we lost customer data when a database node had an issue").

### No custom domain for Route 53 / CloudFront
**Decision:** Route 53 hosted zone uses a placeholder domain (`spooky-shopfront-demo.com`) that isn't actually registered or delegated.

**Why:** This project doesn't own a real domain. The Route 53 zone, alias record, and health check are all real, correctly-configured AWS resources — they just aren't reachable via public DNS resolution since no registrar delegates NS records to this zone. CloudFront was verified independently via its own `*.cloudfront.net` domain, which is fully public and required no domain ownership.

### Security group scoping (least privilege via SG references)
**Decision:** Every internal security group rule references a *source security group ID* rather than a CIDR block — e.g. the app tier only accepts traffic from the ALB's security group; RDS only accepts traffic from the app tier's security group, on port 5432 specifically.

**Why it matters:** This is the AWS-native least-privilege pattern. A CIDR-based rule (e.g. allowing `10.0.0.0/16`) would let *anything* in the VPC reach that resource, including something unrelated spun up later. SG-to-SG references mean only traffic actually originating from an instance carrying that specific security group is allowed — verified directly in Session 4 by confirming a port-reachability test worked from an app instance and would fail from anywhere else in the VPC.

### Credentials via Secrets Manager, never in code
**Decision:** The RDS master password is generated at apply-time with the `random_password` resource and stored in AWS Secrets Manager. It is never hardcoded in `.tf` files or committed to version control.

**Why it matters:** This project's deliverables include a public GitHub repository. Any hardcoded credential would be a real, public leak. Terraform references the generated password by resource attribute, not literal value, so nothing sensitive ever appears in the codebase itself (though it's worth noting the value still lives in Terraform state — a production setup would also want state file encryption and restricted access, both already in place here via the S3 backend's `encrypt = true` and bucket-level public access blocking).

---

## Incident: SSM agent not pre-installed on AMI

**Date:** Session 2

**Assumption made:** Amazon Linux 2023 AMIs ship with the `amazon-ssm-agent` pre-installed and running by default, requiring only an IAM role + instance profile for Session Manager access to work.

**Symptom:** After deploying the ASG with a Launch Template granting the correct IAM role (`AmazonSSMManagedInstanceCore` policy attached), instances launched successfully and passed health checks, but never appeared in `aws ssm describe-instance-information` — the output stayed permanently empty.

**Debugging path:**
1. Verified networking layer first (route tables, NAT Gateway state, security group egress, VPC DNS settings) — all correct, ruled out connectivity as the cause.
2. Verified IAM — role, policy attachment, and instance profile were all correctly attached to running instances — ruled out permissions as the cause.
3. Checked instance metadata service (IMDS) config — IMDSv2 enforced with hop limit 2, which is compatible with the SSM agent — ruled out as the cause.
4. Pulled full EC2 console output (`aws ec2 get-console-output`) and found the actual root cause buried in the cloud-init log:
   ```
   Failed to enable unit: Unit file amazon-ssm-agent.service does not exist.
   Failed to restart amazon-ssm-agent.service: Unit amazon-ssm-agent.service not found.
   ```

**Root cause:** The specific AL2023 AMI resolved by the `data "aws_ami"` filter did not include the SSM agent package. The "AL2023 ships with SSM built-in" assumption doesn't hold universally across all AL2023 AMI builds/variants.

**Fix:** Made the SSM agent installation explicit in `user_data` rather than relying on it being present:
```bash
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
```

**Additional complication during debugging:** Lost time debugging a stale/terminated instance ID after triggering an ASG instance refresh — the old instance had already been shut down (confirmed via `systemd-shutdown` / `Power down` lines in its console output), so all checks against it were misleading. Lesson: after any instance refresh or ASG scaling event, always re-fetch current instance IDs before continuing diagnostics.

**Broader lesson:** Never trust implicit assumptions about what's baked into a base image — make critical dependencies explicit in your own automation code, the same way you'd pin a package version rather than assume `pip install` gives you what you expect.

---

## Decision note: AMI version drift via `most_recent = true`

**Context:** Session 4

**Observation:** During an unrelated `terraform plan` (adding the RDS module), Terraform proposed an in-place update to the Launch Template's `image_id`, changing it from one AMI ID to another, even though no code touching the compute module had changed.

**Cause:** The `data "aws_ami" "amazon_linux"` data source is configured with `most_recent = true`, filtering for the newest AMI matching the `al2023-ami-*-x86_64` name pattern. AWS publishes new AL2023 AMI builds regularly (patches, kernel updates, etc.), so this data source re-resolves to a different AMI ID essentially any time a new build has shipped since the last `plan`/`apply` — independent of anything in our own configuration changing.

**Why this matters:** This is a real-world Terraform gotcha worth understanding, not just accepting silently. A data source using `most_recent` (or similar "latest" semantics) means:
- `terraform plan` output is **not fully deterministic day to day** — the same codebase can produce a different plan purely due to time passing and AWS publishing new artifacts, with zero code changes on our end.
- This is a legitimate example of **infrastructure drift risk in IaC**, even when the Terraform code itself hasn't changed.

**Tradeoff, not a bug:**
- **`most_recent = true` (current approach):** automatically picks up security patches and updates on every apply; convenient, but less reproducible/predictable, and could unexpectedly trigger instance replacement if paired with an instance refresh.
- **Pinned AMI ID:** fully reproducible and predictable across applies, but requires a deliberate process (manual bump, or a scheduled job) to pick up security patches — you own that cadence explicitly rather than getting it "for free."

**Real-world relevance:** Many production teams pin AMI IDs explicitly (often via a separate image-building pipeline, e.g. Packer or EC2 Image Builder) specifically to avoid this kind of silent drift, then roll out new AMIs deliberately through a controlled process (blue/green ASG refresh, canary, etc.) rather than letting `most_recent` decide for them implicitly.

**Good interview talking point:** "How do you handle AMI/image drift in Terraform?" — this incident is a concrete, first-hand example to reference, showing awareness of the tradeoff rather than just knowing the syntax.

---

## Incident: CloudWatch RDS dashboard showing no data — wrong dimension value

**Context:** Session 6. CloudWatch dashboard widgets for ASG CPU and ALB metrics populated correctly; the RDS CPU & Free Storage widget stayed empty.

**Root cause:** The Terraform output feeding the `DBInstanceIdentifier` dimension referenced `aws_db_instance.main.id`, which resolves to RDS's internal **Resource ID** (format: `db-XXXXXXXXXXXXXXXXXXXXXXXXXX`) — not the human-readable DB instance identifier that CloudWatch's `AWS/RDS` namespace actually expects for that dimension (e.g. `spooky-db-20260727234546538500000001`). Since the dimension value didn't match any real metric data, CloudWatch simply had nothing to plot — no error, just silently empty widgets.

**Fix:** Changed the output to reference `aws_db_instance.main.identifier` instead of `.id`.

**Lesson:** AWS resources often expose multiple ID-like attributes (ARN, resource ID, identifier/name) that look interchangeable but aren't — using the wrong one doesn't throw an error, it just silently produces no matching data downstream. Worth double-checking which specific attribute a consuming service (like CloudWatch dimensions) actually expects, rather than assuming any "ID-shaped" value will work.

---

## Minor notes

- **Deprecated `dynamodb_table` backend parameter:** Terraform 1.15 flags this parameter as deprecated in favor of `use_lockfile` (a native S3 lockfile mechanism that removes the need for a separate DynamoDB table). Not urgent — the current setup still works correctly — but worth migrating in a future cleanup pass, along with retiring the `spooky-tf-locks` DynamoDB table once the migration is done.
- **CloudFront caching masked ALB load-balancing behavior:** During manual verification, repeated requests to the CloudFront domain kept returning the same backend instance's hostname, initially looking like the ALB had stopped alternating between AZs. This was actually CloudFront correctly caching the response (`default_ttl = 300`) at the edge — the ALB was still load-balancing normally underneath. Confirmed by appending a random query string parameter to force a cache miss, which revealed both instances responding as expected. Good illustration of why cache-key design matters for anything beyond genuinely static content.
