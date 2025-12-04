group "default" {
  targets = [
      "bitbetter-api-custom",
      "bitbetter-identity-custom",
      "bitbetter-lite-custom",
      "bitbetter-licensegen-custom",
      "bitbetter-api-public",
      "bitbetter-identity-public",
      "bitbetter-lite-public",
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
  tags = [
    "${IMAGE_BASE}/api-custom:${BW_VERSION}",
    "${IMAGE_BASE}/api-custom:latest"
  ]
}

target "bitbetter-identity-custom" {
  args = {
      BITWARDEN_BASE = "${BW_BASE}/identity:${BW_VERSION}"
  }
  target = "custom"
  context = "src/bitbetter"
  tags = [
    "${IMAGE_BASE}/identity-custom:${BW_VERSION}",
    "${IMAGE_BASE}/identity-custom:latest"
  ]
}

target "bitbetter-lite-custom" {
  args = {
      BITWARDEN_BASE = "${BW_BASE}/lite:${BW_VERSION}"
  }
  target = "custom"
  context = "src/bitbetter"
  tags = [
    "${IMAGE_BASE}/lite-custom:${BW_VERSION}",
    "${IMAGE_BASE}/lite-custom:latest"
  ]
}

target "bitbetter-licensegen-custom" {
  context = "src/license_gen"
  target = "custom"
  tags = [
    "${IMAGE_BASE}/licensegen-custom:${BW_VERSION}",
    "${IMAGE_BASE}/licensegen-custom:latest"
  ]
}

target "bitbetter-api-public" {
  inherits = ["_certs-context"]
  args = {
    BITWARDEN_BASE = "${BW_BASE}/api:${BW_VERSION}"
  }
  target = "public"
  context = "src/bitbetter"
  tags = [
    "${IMAGE_BASE}/api-public:${BW_VERSION}",
    "${IMAGE_BASE}/api-public:latest"
  ]
}

target "bitbetter-identity-public" {
  inherits = ["_certs-context"]
  args = {
    BITWARDEN_BASE = "${BW_BASE}/identity:${BW_VERSION}"
  }
  target = "public"
  context = "src/bitbetter"
  tags = [
    "${IMAGE_BASE}/identity-public:${BW_VERSION}",
    "${IMAGE_BASE}/identity-public:latest"
  ]
}

target "bitbetter-lite-public" {
  inherits = ["_certs-context"]
  args = {
      BITWARDEN_BASE = "${BW_BASE}/lite:${BW_VERSION}"
  }
  target = "public"
  context = "src/bitbetter"
  tags = [
    "${IMAGE_BASE}/lite-public:${BW_VERSION}",
    "${IMAGE_BASE}/lite-public:latest"
  ]
}

target "bitbetter-licensegen-public" {
  inherits = ["_certs-context"]
  context = "src/license_gen"
  target = "public"
  tags = [
    "${IMAGE_BASE}/licensegen-public:${BW_VERSION}",
    "${IMAGE_BASE}/licensegen-public:latest"
  ]
}

target "bitbetter-certificate-gen" {
  context = "src/cert_gen/docker"
  tags = [
    "${IMAGE_BASE}/certificate-gen:${BW_VERSION}",
    "${IMAGE_BASE}/certificate-gen:latest"
  ]
}
