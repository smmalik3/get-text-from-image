variable "region" {
    default = "us-east-1"
}

variable "OPENAI_API_KEY" {
    type    = string
    default = "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"
}

variable "CLIENT_ID" {
    type = string
    default = "3MVG9sn24bYFReCXJg2RY_3wWdNise2VoSTgdjmQouWeg3TVLTgWYZAXZIJ3XGNCccqTTYzHSo8ZH1KiEqoBx"
}

variable "CLIENT_SECRET" {
    type = string
    default = "1C10E1A374ED0F4730F5F823E0EA87C2941A3E872FA2378EB45987617110A8BE"
}

variable "SF_USERNAME" {
    type = string
    default = "stac2023.tigersharks+admin@gmail.com.stac3-2023"
}

variable "SF_PASSWORD" {
    type = string
    default = "TigerSharks1!"
}

variable "SF_SECURITY_TOKEN" {
    type = string
    default = "vpKYFM0Ly12EFax114nwp7hr"
}

variable "SF_PATCH_URL" {
    type = string
    default = "https://stac3-2023.my.salesforce.com/services/data/v57.0/sobjects/Application__c/a018Y00000tiRqrQAE"
}

variable "LAMBDA_TIMEOUT" {
    type = number
    default = 500
}