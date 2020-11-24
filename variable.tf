variable "keyname" {
  default = "TerraformKey"
}

variable "ec2name" {
  default = "Mysql Backend Server"
}

variable "amiid" {
  default = "ami-015a6758451df3cb9"
}

variable "ec2type" {
  default = "t2.micro"
}

variable "rootpass" {
  default = "PAssword@123"
}

variable "dbuser" {
  default = "dbadmin"
}

variable "dbpass" {
  default = "DataBase@123"
}

locals {
  mysql_install = <<EOF
    #!/bin/bash

    rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm
    sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo
    yum --enablerepo=mysql80-community install mysql-community-server -y
    service mysqld start

    pass=$(grep "A temporary password" /var/log/mysqld.log | awk '{print $NF}')
    echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${var.rootpass}';" | mysql -u root --password=$pass --connect-expired-password

    echo "CREATE USER '${var.dbuser}'@'%' IDENTIFIED WITH mysql_native_password BY '${var.dbpass}';" | mysql -u root --password=${var.rootpass}
    echo "GRANT ALL PRIVILEGES ON *.* TO '${var.dbuser}'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;" | mysql -u root --password=${var.rootpass}
    EOF
}
