#data "aws_ami" "amazon_linux2" {
#  most_recent = true
#  owners      = ["amazon"] 

#  filter {
#    name   = "name"
#    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#  }
#}

#resource "aws_instance" "bastion" {
#  ami                    = data.aws_ami.amazon_linux2.id
#  instance_type          = "t3.micro"
#  subnet_id              = aws_subnet.public_a.id
#  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

#  # 公開IPを付与 (SSH接続のため)
#  associate_public_ip_address = true

#  # 既存のKey Pairを指定 (要作成済)
#  key_name = "MyKeyPairOne"

#  tags = {
#    Name = "bastion-host"
#  }
#}
