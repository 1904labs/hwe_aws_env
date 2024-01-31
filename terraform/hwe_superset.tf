#Supetset node
#resource "aws_instance" "superset_master" {
#  ami = "ami-06aa3f7caf3a30282" #Ubuntu 20.04
#  instance_type     = "t2.large"
# associate_public_ip_address = true
#  subnet_id = aws_subnet.subnet_az1.id
#   tags = {
#    Name = "superset-master"
#  }
#}