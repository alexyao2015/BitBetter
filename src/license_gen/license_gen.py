import json
from datetime import datetime, timedelta
from pathlib import Path
from uuid import uuid4

import jwt
from cryptography.hazmat.primitives.asymmetric.rsa import RSAPrivateKey, RSAPublicKey

from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
    PublicFormat,
    load_pem_private_key,
)


class LicenseGenerator:
    def __init__(self, key_material: bytes):
        self.private_key, self.private_bytes = self.__load_private_key(key_material)
        self.license_dates = self.__gen_license_date_attributes()

    def __gen_license_date_attributes(self) -> dict[str, str]:
        now = datetime.now()
        expire_date = (now + timedelta(days=100 * 365)).strftime("%Y-%m-%dT%H:%M:%S")
        return {
            "Issued": now.strftime("%Y-%m-%dT%H:%M:%S"),
            "Expires": expire_date,
            "Refresh": expire_date,
        }

    def __load_private_key(self, key_material: bytes) -> tuple[RSAPrivateKey, bytes]:
        # Load the RSA private key from bytes
        rsa_private_key = load_pem_private_key(key_material, password=None)
        assert isinstance(rsa_private_key, RSAPrivateKey)  # Ensure it's an RSA key

        private_bytes = rsa_private_key.private_bytes(
            Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()
        )
        return rsa_private_key, private_bytes

    def __get_public_key(
        self, private_key: RSAPrivateKey
    ) -> tuple[RSAPublicKey, bytes]:
        public_key = private_key.public_key()
        assert isinstance(public_key, RSAPublicKey)  # Ensure it's an RSA public key
        public_bytes = public_key.public_bytes(
            Encoding.PEM, PublicFormat.SubjectPublicKeyInfo
        )
        return public_key, public_bytes

    def __gen_uuid(self) -> str:
        return str(uuid4())

    def __build_jwt(
        self,
        attributes: dict,
        user_id: str | None = None,
        organization_id: str | None = None,
    ) -> str:
        if user_id and organization_id:
            raise Exception("Cannot specify both user_id and organization_id")
        if user_id:
            aud = f"user:{user_id}"
        elif organization_id:
            aud = f"organization:{organization_id}"
        else:
            raise Exception("Must specify either user_id or organization_id")

        now = datetime.now()
        expires_ts = (now + timedelta(days=100 * 365)).timestamp()
        jwt_payload = {
            # "sub": "notchecked",
            "aud": aud,
            "iss": "bitwarden",
            "exp": int(expires_ts),
            # "nbf": int(int(now.timestamp())),
            "jti": self.__gen_uuid(),
        }
        jwt_payload.update(attributes)
        if "LicenseType" in jwt_payload:
            if jwt_payload["LicenseType"] == 0:
                jwt_payload["LicenseType"] = "User"
            elif jwt_payload["LicenseType"] == 1:
                jwt_payload["LicenseType"] = "Organization"
            else:
                raise Exception(f"Invalid LicenseType {jwt_payload['LicenseType']}")
        return jwt.encode(
            jwt_payload,
            self.private_key,
            algorithm="RS256",
        )

    def build_user_license(self, id: str, email: str, name: str) -> str:
        license = {
            "LicenseType": 0,
            "Id": id,  # Must match aud id
            "LicenseKey": self.__gen_uuid(),
            "Name": name,
            "Email": email,
            "Premium": True,
            # "MaxStorageGb": max_storage_gb,
            "Trial": False,
        }
        license.update(self.license_dates)
        license["Token"] = self.__build_jwt(license, user_id=id)
        return json.dumps(license)

    def interactive_request_user_license(self) -> str:
        id = input("Enter user id (must match user id in Bitwarden): ")
        email = input("Enter user email (must match email in Bitwarden): ")
        name = input("Enter user name (can be anything): ")
        return self.build_user_license(id, email, name)

    def interactive_request_organization_license(self) -> str:
        install_id = input("Enter install id (must match install id in Bitwarden): ")
        org_name = input(
            "Enter organization name (will appear in Bitwarden interface, can be anything): "
        )
        email = input("Enter billing email (can be anything): ")
        return self.build_organization_license(install_id, org_name, email)

    def build_organization_license(
        self, install_id: str, org_name: str, email: str
    ) -> str:
        now = datetime.now()
        expiration_time = (now + timedelta(days=100 * 365)).strftime(
            "%Y-%m-%dT%H:%M:%S"
        )
        org_id = self.__gen_uuid()
        license = {
            "Version": 15,
            "Enabled": True,
            "LicenseType": 1,
            "LicenseKey": self.__gen_uuid(),
            "InstallationId": install_id,
            "Id": org_id,  # Must match aud id
            "Name": org_name,
            "BusinessName": org_name,
            "BillingEmail": email,
            "Plan": "Enterprise (Annually)",
            "PlanType": 20,
            "SelfHost": True,
            "Trial": False,
            # Not applicable to self host because disabled
            # "MaxStorageGb": 32767,  # Max short int
            # Exclude maximums to allow unlimited
            # "Seats": 32767, # Max short int
            # "MaxCollections": 32767, # Max short int
            # "SmSeats": 32767,  # Max short int
            # "SmServiceAccounts": 32767,  # Max short int
            # Begin features
            "UsePolicies": True,
            "UseSso": True,
            "UseKeyConnector": True,
            "UseScim": True,
            "UseGroups": True,
            "UseEvents": True,
            "UseDirectory": True,
            "UseTotp": True,
            "Use2fa": True,
            "UseApi": True,
            "UseResetPassword": True,
            "UsersGetPremium": True,
            "UseCustomPermissions": True,
            "UsePasswordManager": True,
            "UseSecretsManager": True,
            "UseRiskInsights": True,
            "UseOrganizationDomains": True,
        }
        license.update(self.license_dates)
        license["Token"] = self.__build_jwt(license, organization_id=org_id)
        return json.dumps(license)


if __name__ == "__main__":
    key_material = Path("/bitbetter/certs/bitbetter.key").read_bytes()
    license_generator = LicenseGenerator(key_material)
    license_type = input("Generate a (U)ser or (o)rganization license? (U/o) ").lower()
    if license_type == "o":
        license_json = license_generator.interactive_request_organization_license()
    else:
        license_json = license_generator.interactive_request_user_license()
    print(license_json)
    Path("/bitbetter/output/license.json").write_text(license_json)
