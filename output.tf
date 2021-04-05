output "ec2-ip"  {
  value = aws_instance.web.public_ip
}

output "docdb-cluster-endpoint" {
  value = aws_docdb_cluster.docdb.endpoint
}

output "docdb-reader-endpoint" {
  value = aws_docdb_cluster.docdb.reader_endpoint
}

output "az" {
  value = element(tolist(aws_docdb_cluster.docdb.availability_zones),  1 % length(aws_docdb_cluster.docdb.availability_zones) )
}

