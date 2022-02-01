module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  name        = "my-tgw"
  description = "My TGW shared with several other AWS accounts"
  amazon_side_asn = 64532

  enable_auto_accept_shared_attachments = true
  share_tgw =  false

  vpc_attachments = {
    vpc1 = {
      vpc_id       = module.vpc-public.vpc_id
      subnet_ids   = module.vpc-public.private_subnets
      dns_support  = true
    #   ipv6_support = true
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true
      #   transit_gateway_route_table_id = "tgw-rtb-073a181ee589b360f"

      tgw_routes = [
        {
          destination_cidr_block = "10.10.0.0/16"
        },
        {
          blackhole              = true
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    },
    vpc2 = {
      vpc_id     =  module.vpc-private.vpc_id
      subnet_ids =  module.vpc-private.private_subnets
      dns_support  = true
    #   ipv6_support = true
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      tgw_routes = [
        {
          destination_cidr_block = "10.20.0.0/16"
        }
      ]
    },
  }

#   ram_allow_external_principals = true
#   ram_principals = [307990089504]

  tags = {
    Purpose = "tgw-complete-example"
  }
}

module "vpc-public" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc-public"

  cidr = "10.10.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets =  ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnets = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group  = true
  default_security_group_name = "sg-default"

  default_security_group_egress = [{
    cidr_blocks = "0.0.0.0/0"
  }]

  default_security_group_ingress = [
    {
        description = "Allow all internal TCP and UDP"
        self        = true
    },
    {
        description = "Allow all internal using tgw"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = "10.0.0.0/8"
    }
  ]

  public_subnet_tags = {
    "Network Type" = "Public"
  }

  private_subnet_tags = {
    "Network Type" = "Private"
  }
  
#   private_subnet_ipv6_prefixes                   = [0, 1, 2]
}

resource "aws_route" "transit_gateway_vpc1_public" {
  count                  = length(module.vpc-public.public_route_table_ids)
  route_table_id         = module.vpc-public.public_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}

resource "aws_route" "transit_gateway_vpc1" {
  count                  = length(module.vpc-public.private_route_table_ids)
  route_table_id         = module.vpc-public.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}

module "vpc-private" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "vpc-private"

  cidr = "10.20.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group  = true
  default_security_group_name = "sg-default"

  default_security_group_egress = [{
    cidr_blocks = "0.0.0.0/0"
  }]

  default_security_group_ingress = [
    {
        description = "Allow all internal TCP and UDP"
        self        = true
    },
    {
        description = "Allow all internal using tgw"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = "10.0.0.0/8"
    }
  ]

  private_subnet_tags = {
    "Network Type" = "Private"
  }
#   private_subnet_ipv6_prefixes                   = [0, 1, 2]
}


resource "aws_route" "transit_gateway_vpc2" {
  count                  = length(module.vpc-private.private_route_table_ids)
  route_table_id         = module.vpc-private.private_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.tgw.ec2_transit_gateway_id
}