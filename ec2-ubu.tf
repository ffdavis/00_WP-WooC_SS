resource "aws_instance" "StoreOne-ec2" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.StoreOneSNPublic.id}"
  vpc_security_group_ids      = ["${aws_security_group.StoreOneSG.id}"]

  key_name = "${var.key_name}"

  tags = {
    Name = "StoreOne-ec2"
  }
}

locals {
  STOREONEEC2DPUBIP  = "${aws_instance.StoreOne-ec2.public_ip}"
  STOREONEEC2DNSNAME = "${aws_instance.StoreOne-ec2.public_dns}"
}

resource "null_resource" "StoreOne-ec2-copy" {
  provisioner "file" {
    source      = "userdata.sh"
    destination = "~/userdata.sh"

    connection {
      host        = "${aws_instance.StoreOne-ec2.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("c:/tmp/AWS Keys/myKey.pem")}"
      timeout     = "10m"
      agent       = "false"
    }
  }

  provisioner "file" {
    source      = "phptest.php"
    destination = "~/phptest.php"

    connection {
      host        = "${aws_instance.StoreOne-ec2.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("c:/tmp/AWS Keys/myKey.pem")}"
      timeout     = "10m"
      agent       = "false"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 744 ~/userdata.sh",
      "sudo sleep 180",                                                       # I had to add a sleep of 180 to get the "apt install apache2 -y" defined in userdate.sh, working ok.
      "~/userdata.sh ${local.STOREONEEC2DPUBIP} ${local.STOREONEEC2DNSNAME}",
    ]

    connection {
      host        = "${aws_instance.StoreOne-ec2.public_ip}"
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("c:/tmp/AWS Keys/myKey.pem")}"
      timeout     = "10m"
      agent       = "false"
    }
  }
}
