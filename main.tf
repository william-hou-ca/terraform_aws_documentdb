provider "aws" {
  region = "ca-central-1"
}

###########################################################################
#
# Create a docDB cluster and attach 2 instances to it
#
###########################################################################

resource "aws_docdb_cluster" "docdb" {

  skip_final_snapshot     = true
  apply_immediately = true


  # Configuration
  cluster_identifier      = "my-docdb-cluster"
  engine                  = "docdb"
  engine_version = "4.0.0"

  # Authentication
  master_username         = var.db.master_name
  master_password         = var.db.password

  # Network settings
  db_subnet_group_name = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = data.aws_security_groups.default_sg.ids
  #availability_zones = ["ca-central-1a", "ca-central-1b"]

  # Cluster options
  port = 27017
  db_cluster_parameter_group_name  = aws_docdb_cluster_parameter_group.this.name

  # Encryption-at-rest
  storage_encrypted = false
  # kms_key_id = 

  # Backup
  backup_retention_period = 1
  preferred_backup_window = "01:00-03:00"

  # Log exports
  # enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  # Maintenance
  preferred_maintenance_window = "wed:04:00-wed:04:30"

  # Tags
  tags = {
    type = "docdb"
    env = "dev"
    numberinstance = "2"
  }

  # Deletion protection
  deletion_protection = false

}

# join instances to docDB cluster
resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 2 #Number of instances
  identifier         = "docdb-cluster-demo-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"

  availability_zone = element(tolist(aws_docdb_cluster.docdb.availability_zones),  count.index % length(aws_docdb_cluster.docdb.availability_zones) )
}


###########################################################################
#
# Create a subnet group
#
###########################################################################

resource "aws_docdb_subnet_group" "this" {
  name       = "tf-docdb-subnet"
  subnet_ids = data.aws_subnet_ids.default_subnets.ids

  tags = {
    Name = "My docdb subnet group"
  }
}

###########################################################################
#
# Create a parameters group
#
###########################################################################

resource "aws_docdb_cluster_parameter_group" "this" {
  family      = "docdb4.0"
  name        = "tf-docdb-paragroup"
  description = "docdb cluster parameter group"

  /*
  parameter {
    name  = "tls"
    value = "enabled"
  }
  */
}

###########################################################################
#
# ec2 instance in the default vpc and install mongodb client in it
#
###########################################################################

resource "aws_instance" "web" {
  #count = 0 #if count = 0, this instance will not be created.

  #required parametres
  ami           = "ami-09934b230a2c41883"
  instance_type = "t2.micro"

  #optional parametres
  associate_public_ip_address = true
  key_name = "key-hr123000" #key paire name exists in aws.

  vpc_security_group_ids = data.aws_security_groups.default_sg.ids

  tags = {
    Name = "HelloWorld"
  }

  user_data = <<-EOF
          #! /bin/sh
          sudo yum update -y
          sudo amazon-linux-extras install epel -y 
          echo -e "[mongodb-org-4.0] \nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/4.0/x86_64/\ngpgcheck=1 \nenabled=1 \ngpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-4.0.repo
          sudo yum install -y mongodb-org-shell
          sudo  wget -O /tmp/rds-combined-ca-bundle.pem https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
EOF
}
