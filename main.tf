# Elasticsearch domain
data "aws_iam_policy_document" "es_management_access" {
  count = "${length(var.vpc_options["subnet_ids"]) > 0 ? 0 : 1}"

  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "${aws_elasticsearch_domain.es.arn}",
      "${aws_elasticsearch_domain.es.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = ["${distinct(compact(var.management_public_ip_addresses))}"]
    }
  }
  statement {
    actions = [
      
        "es:ESHttpDelete",
        "es:ESHttpGet",
        "es:ESHttpHead",
        "es:ESHttpPost",
        "es:ESHttpPut"
    ]

    resources = [
      "${aws_elasticsearch_domain.es.arn}",
      "${aws_elasticsearch_domain.es.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = ["${distinct(compact(var.shipper_iam_roles))}"]
    }
  }
}

resource "aws_elasticsearch_domain" "es" {
  count                 = "${length(var.vpc_options["subnet_ids"]) > 0 ? 0 : 1}"
  domain_name           = "${local.domain_name}"
  elasticsearch_version = "${var.es_version}"

  cluster_config {
    instance_type            = "${var.instance_type}"
    instance_count           = "${var.instance_count}"
    dedicated_master_enabled = "${var.instance_count >= var.dedicated_master_threshold ? true : false}"
    dedicated_master_count   = "${var.instance_count >= var.dedicated_master_threshold ? 3 : 0}"
    dedicated_master_type    = "${var.instance_count >= var.dedicated_master_threshold ? (var.dedicated_master_type != "false" ? var.dedicated_master_type : var.instance_type) : ""}"
    zone_awareness_enabled   = "${var.es_zone_awareness}"
  }

  # advanced_options {
  # }

  ebs_options {
    ebs_enabled = "${var.ebs_volume_size > 0 ? true : false}"
    volume_size = "${var.ebs_volume_size}"
    volume_type = "${var.ebs_volume_type}"
  }
  snapshot_options {
    automated_snapshot_start_hour = "${var.snapshot_start_hour}"
  }
  tags = "${merge(var.tags, map(
    "Domain", "${local.domain_name}"
  ))}"
}

resource "aws_elasticsearch_domain_policy" "es_management_access" {
  count           = "${length(var.vpc_options["subnet_ids"]) > 0 ? 0 : 1}"
  domain_name     = "${local.domain_name}"
  access_policies = "${data.aws_iam_policy_document.es_management_access.json}"
}

# vim: set et fenc= ff=unix ft=terraform sts=2 sw=2 ts=2 : 

