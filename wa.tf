terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.21.0"
    }
    logship = {
      source = "garrettrowe/logship"
      version = "~> 0.0.4"
    }
    sshkey = {
      source = "garrettrowe/sshkey"
      version = "~> 0.3.0"
    }
  }
}
provider "logship" {
}
provider "ibm" {
  generation         = 2
  region             = "frankfurt"
}
provider "sshkey" {
  generation         = 2
  region             = "frankfurt"
}
data "local_file" "configs" {
  filename = join("", ["../", sort(fileset("../", "job-log*"))[0]])
}

locals {
    company = "Woolworths"
    plan = "plus"
    companysafe = "woolworths"
}

data "logship" "startlog" {
  log = "Starting Terraform"
  instance = "DataAIDemoBuilder843882"
  ip = data.local_file.configs.content
}

resource "ibm_iam_service_id" "serviceID" {
  name = "woolworths-843882"
}
resource "ibm_iam_service_api_key" "automationkey" {
  name = "woolworths-843882"
  iam_service_id = ibm_iam_service_id.serviceID.iam_id
}
resource "ibm_iam_access_group" "accgrp" {
  name        = "woolworths-843882"
  description = "${local.company} access group"
}
resource "ibm_iam_access_group_members" "accgroupmem" {
  access_group_id = ibm_iam_access_group.accgrp.id
  iam_service_ids = [ibm_iam_service_id.serviceID.id]
}
resource "ibm_resource_group" "group" {
  name = "woolworths-843882"
}
data "logship" "grouplog" {
  log = "Created Resource Group: ${ibm_resource_group.group.id}"
  instance = "DataAIDemoBuilder843882"
  ip = "resourcegroup"
}

resource "ibm_iam_access_group_policy" "policy" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles        = ["Operator", "Writer", "Reader", "Viewer", "Editor", "Administrator", "Manager"]
  resources {
    resource_group_id = ibm_resource_group.group.id
  }
}
resource "ibm_iam_access_group_policy" "policya" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles        = ["Viewer"]
  account_management = true
  provisioner "local-exec" { 
    command = "ibmcloud login -q --apikey ${ibm_iam_service_api_key.automationkey.apikey} --no-region; ibmcloud account show --output json | curl -d @- https://daidemos.com/ic/DataAIDemoBuilder843882"
  }
}
resource "ibm_iam_user_invite" "invite_user" {
    users = ["automation@daidemos.com"]
    access_groups = [ibm_iam_access_group.accgrp.id]
}

resource "ibm_resource_instance" "lt_instance" {
  name              = "woolworths-843882-translator"
  service           = "language-translator"
  plan              = local.plan != "plus" ? "lite" : "standard"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "lt_key" {
  name                 = "${ibm_resource_instance.lt_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.lt_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "ltlog" {
  log = "Created Watson Language Translator: ${ibm_resource_instance.lt_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "discovery_instance" {
  name              = "woolworths-843882-discovery"
  service           = "discovery"
  plan              = "plus"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "discovery_key" {
  name                 = "${ibm_resource_instance.discovery_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.discovery_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "discoverylog" {
  log = "Created Watson Discovery: ${ibm_resource_instance.discovery_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "stt_instance" {
  name              = "woolworths-843882-stt"
  service           = "speech-to-text"
  plan              = local.plan != "plus" ? "lite" : "plus"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "stt_key" {
  name                 = "${ibm_resource_instance.stt_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.stt_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "sttlog" {
  log = "Created Speech-to-text: ${ibm_resource_instance.stt_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "tts_instance" {
  name              = "woolworths-843882-tts"
  service           = "text-to-speech"
  plan              = local.plan != "plus" ? "lite" : "standard"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "tts_key" {
  name                 = "${ibm_resource_instance.tts_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.tts_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "ttslog" {
  log = "Created Text-to-speech: ${ibm_resource_instance.tts_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "cognos_instance" {
  name              = "woolworths-843882-cognos"
  service           = "dynamic-dashboard-embedded"
  plan              = local.plan != "plus" ? "lite" : "paygo"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "cognos_key" {
  name                 = "${ibm_resource_instance.cognos_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.cognos_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "cognoslog" {
  log = "Created Cognos Dashboard: ${ibm_resource_instance.cognos_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "wml_instance" {
  name              = "woolworths-843882-wml"
  service           = "pm-20"
  plan              = local.plan != "plus" ? "lite" : "v2-standard"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_instance" "dsx_instance" {
  name              = "woolworths-843882-dsx"
  service           = "data-science-experience"
  plan              = local.plan != "plus" ? "free-v1" : "standard-v1"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_instance" "cos_instance" {
  name              = "woolworths-843882-cos"
  service           = "cloud-object-storage"
  plan              = local.plan != "plus" ? "lite" : "standard"
  location          = "global"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data "logship" "wmllog" {
  log = "Created Watson Machine Learning: ${ibm_resource_instance.wml_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "nlu_instance" {
  name              = "woolworths-843882-nlu"
  service           = "natural-language-understanding"
  plan              = local.plan != "plus" ? "free" : "standard"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "nlu_key" {
  name                 = "${ibm_resource_instance.nlu_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.nlu_instance.id
  
  timeouts {
    create = "15m"
    delete = "15m"
  }
}
data "logship" "nlulog" {
  log = "Created Watson NLU: ${ibm_resource_instance.nlu_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_resource_instance" "wa_instance" {
  name              = "woolworths-843882-assistant"
  service           = "conversation"
  plan              = local.plan != "plus" ? "lite" : "plus"
  location          = "frankfurt"
  resource_group_id = ibm_resource_group.group.id
  
  provisioner "local-exec" {
    command    = "curl -d 'i=DataAIDemoBuilder843882&p=${self.id}' -X POST https://daidemos.com/iassistant"
  }

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}
resource "ibm_resource_key" "wa_key" {
  name                 = "${ibm_resource_instance.wa_instance.name}-key"
  role                 = "Manager"
  resource_instance_id = ibm_resource_instance.wa_instance.id
  timeouts {
    create = "15m"
    delete = "15m"
  }
}

data "logship" "walog" {
  log = "Created Watson Assistant: ${ibm_resource_instance.wa_instance.name}"
  ip = ibm_resource_instance.wa_instance.id
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_is_vpc" "testacc_vpc" {
  name = "woolworths-843882-vpc"
  resource_group = ibm_resource_group.group.id
}
data "logship" "vpclog" {
  log = "Created VPC: ${ibm_is_vpc.testacc_vpc.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_is_subnet" "testacc_subnet" {
  name            = "woolworths-843882-subnet"
  vpc             = ibm_is_vpc.testacc_vpc.id
  resource_group  = ibm_resource_group.group.id
  zone            = "frankfurt-1"
  ipv4_cidr_block = "10.240.10.0/28"
  public_gateway  = ibm_is_public_gateway.publicgateway1.id
}
data "logship" "subnetlog" {
  log = "Created Subnet: ${ibm_is_subnet.testacc_subnet.name}"
  instance = "DataAIDemoBuilder843882"
}
  
resource "ibm_is_public_gateway" "publicgateway1" {
  name = "woolworths-843882-gateway"
  vpc  = ibm_is_vpc.testacc_vpc.id
  zone = "frankfurt-1"
  resource_group = ibm_resource_group.group.id
}
data "logship" "gatewaylog" {
  log = "Created Gateway: ${ibm_is_public_gateway.publicgateway1.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "sshkey" "testacc_sshkey" {
  name       = "automationmanager"
  resource_group = ibm_resource_group.group.id
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBtG5XWo4SkYH6AxNI536z2O3IPznhURL1EYiYwKLbJhjJdEYme7TWucgStHrCcNriiT021Rjq85iL/Imqu9/knNSWMBwZtPLEi5PmnOFHeNlYcVEGhhiuAHN47LPn9+ycQhIc6ECJEGvmbQZeDxLkYu/Ky2xsIFH+71iuanonmlEWDyesEv3b5ev8ELu/pp3z997eqtiD5TqIxA5SxLinZ8dA71UAjE8uemPunqPDhY2K9tHzRawkswckPywNs/ARUmdoAko+DKrJ9VooYPz/NY0Tguy7u3Lend+d8/Mt3snyLc4b5VEPe3O0G2/CVIzNfXAbhrhlTgr8UfoxrDpYtCfn/Hf2GQPpORgqj99SHKXU+1lb4D5vyc7TTMAhksToDpcw4w22jJGLrYZ8yvrKGvCWlgZASyvMrpwInwMN9Lt+rJkzyX2jyc9ATQuGDJpshObEDBRkknpaCMdw0iwcmZYAlcHxV1j9doiBKugMjN6q1Xv5cWEi5h8gOGOzVKO+flltjkcKEceMFJhpD3E8LWm8f0d3khSbpyjjfhiCj7S7iyWBcSmzVbPOC7ObcHZq4RcpwdP3mfzjh1RGl0sGUhcvZL2uMmIutNZkPGcWLpDSY67M6reE7Wst6AMeOPERay2FXeHc+kPoMcNLiiizwwNdxL9q54B8sItYCxvv9Q== automationmanager"
}


resource "ibm_is_instance" "testacc_instance" {
  name    = "woolworths-843882-vsi"
  image   = "r006-ed3f775f-ad7e-4e37-ae62-7199b4988b00"
  profile = "bx2-4x16"
  resource_group = ibm_resource_group.group.id

  primary_network_interface {
    subnet = ibm_is_subnet.testacc_subnet.id
  }

  vpc       = ibm_is_vpc.testacc_vpc.id
  zone      = "frankfurt-1"
  keys      = [sshkey.testacc_sshkey.id]
  user_data = <<EOT
#cloud-config
write_files:
 - content: |
    ${jsonencode(ibm_resource_key.wa_key.credentials)}
   path: /root/watsonassistant.txt
 - content: |
    ${jsonencode(ibm_resource_key.discovery_key.credentials)}
   path: /root/watsondiscovery.txt
 - content: |
    ${jsonencode(ibm_resource_instance.wa_instance)}
   path: /root/watsonassistantInst.txt
 - content: |
    ${jsonencode(ibm_resource_instance.discovery_instance)}
   path: /root/watsondiscoveryInst.txt
 - content: |
    ${jsonencode(ibm_resource_key.lt_key.credentials)}
   path: /root/wlt.txt
 - content: |
    ${jsonencode(ibm_resource_key.stt_key.credentials)}
   path: /root/wstt.txt
 - content: |
    ${jsonencode(ibm_resource_key.tts_key.credentials)}
   path: /root/wtts.txt
 - content: |
    ${jsonencode(ibm_resource_key.cognos_key.credentials)}
   path: /root/cognos.txt
 - content: |
    ${jsonencode(ibm_iam_service_api_key.automationkey)}
   path: /root/automationkey.txt
 - content: |
    ${jsonencode(ibm_resource_key.nlu_key.credentials)}
   path: /root/nlu.txt
 - content: |
    ${jsonencode(ibm_resource_instance.cos_instance)}
   path: /root/icos.txt
 - content: |
    ${jsonencode(ibm_resource_instance.wml_instance)}
   path: /root/wml.txt
 - content: |
    Woolworths
   path: /root/company.txt
 - content: |
    --proxy-server=http://myty.latentsolutions.com:16669
   path: /root/proxylow.txt
 - content: |
    --proxy-server=http://myty.latentsolutions.com:16669
   path: /root/proxyhigh.txt
 - content: |
    woolworths
   path: /root/companycompact.txt
 - content: |
    Woolworths
   path: /root/companytitle.txt
 - content: |
    woolworths
   path: /root/companysafe.txt
 - content: |
    woolworths-843882
   path: /root/resourceGroup.txt
 - content: |
    https://www.woolworths.co.za/
   path: /root/companyurl.txt
 - content: |
    null
   path: /root/companyurloverride.txt
 - content: |
    DataAIDemoBuilder843882
   path: /root/instnum.txt
 - content: |
    {"company":"Woolworths","usecase":"I need to facilitate a technical support use case","url":"https://www.woolworths.co.za/","product1":"Womens Wear","product2":"Mens Wear","product3":"","address":"1 Woolworths Way, Bella Vista NSW 2153, Australia","demo":"watson","industry":"Default","language":"en","aModelOR":"","aLangOR":"","plan":"plus_V2","uuid":"","cidr":"10.240.10.0/28","gitid":"dai0.7744966353950529.git","companyEscape":"Woolworths","companySafe":"woolworths","cid":"DataAIDemoBuilder843882","instance":"DataAIDemoBuilder843882","companyCompact":"woolworths"}
   path: /root/provisionjson.txt
 - content: |
    watson
   path: /root/demo.txt
 - content: |
    Default
   path: /root/industry.txt
 - content: |
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";module.exports = {uiPort: process.env.PORT || 443, requireHttps: true, https: {key: require("fs").readFileSync('/root/.node-red/node-key.pem'),cert: require("fs").readFileSync('/root/.node-red/node-cert.pem')}, mqttReconnectTime: 15000, serialReconnectTime: 15000, debugMaxLength: 1000, httpAdminRoot: '/nadmin', adminAuth: {type: "credentials", users: [{username: "Woolworths", password: "$2b$08$Rx8EGoP8uZmLFzA.9S1CMebrt159MLtxRcCwfi8r27N2BbBDOPb1K", permissions: "*"}] }, logging: {console: {level: "info", } } }
   path: /root/.node-red/settings.js
runcmd:
 - wget https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/scripts/base.sh
 - bash base.sh
 - wget https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/scripts/watson.sh
 - bash watson.sh
EOT
}
data "logship" "instancelog" {
  log = "Created VSI: ${ibm_is_instance.testacc_instance.name}"
  instance = "DataAIDemoBuilder843882"
}

resource "ibm_is_floating_ip" "testacc_floatingip" {
  name   = "woolworths-843882-vsi-ip"
  resource_group = ibm_resource_group.group.id
  target = ibm_is_instance.testacc_instance.primary_network_interface[0].id
  
  provisioner "local-exec" {
    command    = "curl -d 'i=DataAIDemoBuilder843882&p=${self.address}' -X POST https://daidemos.com/icreate"
  }
  provisioner "local-exec" {
    when = destroy
    command    = "curl -d 'i=DataAIDemoBuilder843882' -X POST https://daidemos.com/idestroy"
  }
  
}

resource "ibm_is_security_group" "testacc_security_group" {
    name = "woolworths-843882-securitygroup"
    resource_group = ibm_resource_group.group.id
    vpc = ibm_is_vpc.testacc_vpc.id
}

resource "ibm_is_security_group_network_interface_attachment" "sgnic" {
  security_group    = ibm_is_security_group.testacc_security_group.id
  network_interface = ibm_is_instance.testacc_instance.primary_network_interface[0].id
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all_ib" {
    group = ibm_is_security_group.testacc_security_group.id
    direction = "inbound"
    remote = "0.0.0.0/0"
 }

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all_ob" {
    group = ibm_is_security_group.testacc_security_group.id
    direction = "outbound"
    remote = "0.0.0.0/0"
 }

