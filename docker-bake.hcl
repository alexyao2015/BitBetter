group "default" {
  targets = [
      "bitbetter-api-custom",
      "bitbetter-identity-custom",
      "bitbetter-self-host-custom",
      "bitbetter-licensegen-custom",
      "bitbetter-api-public",
      "bitbetter-identity-public",
      "bitbetter-self-host-public",
      "bitbetter-licensegen-public",
      "bitbetter-certificate-gen"
  ]
}

variable "BW_VERSION" {
  default = "$BW_VERSION"
}

variable "IMAGE_BASE" {
  default = "bitbetter"
}

variable "BW_BASE" {
  default = "ghcr.io/bitwarden"
}

target "_certs-context" {
  contexts = {
    certs = "src/cert_gen/certs"
  }
}

target "bitbetter-api-custom" {
  args = {
      BITWARDEN_BASE = "${BW_BASE}/api:${BW_VERSION}"
  }
  target = "custom"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/api:${BW_VERSION}"]
}

target "bitbetter-identity-custom" {
  args = {
      BITWARDEN_BASE = "${BW_BASE}/identity:${BW_VERSION}"
  }
  target = "custom"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/identity:${BW_VERSION}"]
}

target "bitbetter-self-host-custom" {
  args = {
      BITWARDEN_BASE = "${BW_BASE}/self-host:${BW_VERSION}-beta"
  }
  target = "custom"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/self-host:${BW_VERSION}"]
}

target "bitbetter-licensegen-custom" {
  context = "src/license_gen"
  target = "custom"
  tags = ["${IMAGE_BASE}/licensegen:${BW_VERSION}"]
}

target "bitbetter-api-public" {
  inherits = ["_certs-context"]
  args = {
    BITWARDEN_BASE = "${BW_BASE}/api:${BW_VERSION}"
  }
  target = "public"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/api:${BW_VERSION}"]
}

target "bitbetter-identity-public" {
  inherits = ["_certs-context"]
  args = {
    BITWARDEN_BASE = "${BW_BASE}/identity:${BW_VERSION}"
  }
  target = "public"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/identity:${BW_VERSION}"]
}

target "bitbetter-self-host-public" {
  inherits = ["_certs-context"]
  args = {
      BITWARDEN_BASE = "${BW_BASE}/self-host:${BW_VERSION}-beta"
  }
  target = "public"
  context = "src/bitbetter"
  tags = ["${IMAGE_BASE}/self-host:${BW_VERSION}"]
}

target "bitbetter-licensegen-public" {
  inherits = ["_certs-context"]
  context = "src/license_gen"
  target = "public"
  tags = ["${IMAGE_BASE}/licensegen:${BW_VERSION}"]
}

target "bitbetter-certificate-gen" {
  context = "src/cert_gen/docker"
  tags = ["${IMAGE_BASE}/certificate-gen:${BW_VERSION}"]
}
