variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "The location for the key ring (e.g., us-central1, global)"
  type        = string
}

variable "key_ring_name" {
  description = "The name of the key ring"
  type        = string
}

variable "crypto_keys" {
  description = "List of crypto keys to create"
  type = list(object({
    name             = string
    purpose          = string
    rotation_period  = string
    algorithm        = string
    protection_level = string
    labels           = map(string)
    version_template = object({
      algorithm        = string
      protection_level = string
    })
  }))
  default = []

  validation {
    condition = alltrue([
      for key in var.crypto_keys : contains([
        "ENCRYPT_DECRYPT",
        "ASYMMETRIC_SIGN",
        "ASYMMETRIC_DECRYPT",
        "MAC"
      ], key.purpose)
    ])
    error_message = "Purpose must be one of: ENCRYPT_DECRYPT, ASYMMETRIC_SIGN, ASYMMETRIC_DECRYPT, MAC."
  }

  validation {
    condition = alltrue([
      for key in var.crypto_keys : contains([
        "SOFTWARE",
        "HSM",
        "EXTERNAL",
        "EXTERNAL_VPC"
      ], key.protection_level)
    ])
    error_message = "Protection level must be one of: SOFTWARE, HSM, EXTERNAL, EXTERNAL_VPC."
  }

  validation {
    condition = alltrue([
      for key in var.crypto_keys : contains([
        "GOOGLE_SYMMETRIC_ENCRYPTION",
        "RSA_SIGN_PSS_2048_SHA256",
        "RSA_SIGN_PSS_3072_SHA256",
        "RSA_SIGN_PSS_4096_SHA256",
        "RSA_SIGN_PSS_4096_SHA512",
        "RSA_SIGN_PKCS1_2048_SHA256",
        "RSA_SIGN_PKCS1_3072_SHA256",
        "RSA_SIGN_PKCS1_4096_SHA256",
        "RSA_SIGN_PKCS1_4096_SHA512",
        "RSA_SIGN_RAW_PKCS1_2048",
        "RSA_SIGN_RAW_PKCS1_3072",
        "RSA_SIGN_RAW_PKCS1_4096",
        "RSA_DECRYPT_OAEP_2048_SHA256",
        "RSA_DECRYPT_OAEP_3072_SHA256",
        "RSA_DECRYPT_OAEP_4096_SHA256",
        "RSA_DECRYPT_OAEP_4096_SHA512",
        "RSA_DECRYPT_OAEP_2048_SHA1",
        "RSA_DECRYPT_OAEP_3072_SHA1",
        "RSA_DECRYPT_OAEP_4096_SHA1",
        "EC_SIGN_P256_SHA256",
        "EC_SIGN_P384_SHA384",
        "EC_SIGN_SECP256K1_SHA256",
        "HMAC_SHA256",
        "HMAC_SHA1",
        "HMAC_SHA384",
        "HMAC_SHA512",
        "HMAC_SHA224",
        "EXTERNAL_SYMMETRIC_ENCRYPTION"
      ], key.algorithm)
    ])
    error_message = "Invalid algorithm specified."
  }
}

variable "key_iam_bindings" {
  description = "IAM bindings for crypto keys"
  type = list(object({
    key_name = string
    role     = string
    members  = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for binding in var.key_iam_bindings : contains([
        "roles/cloudkms.cryptoKeyEncrypter",
        "roles/cloudkms.cryptoKeyDecrypter",
        "roles/cloudkms.cryptoKeyEncrypterDecrypter",
        "roles/cloudkms.signer",
        "roles/cloudkms.signerVerifier",
        "roles/cloudkms.viewer",
        "roles/cloudkms.admin"
      ], binding.role)
    ])
    error_message = "Role must be a valid Cloud KMS IAM role."
  }
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
