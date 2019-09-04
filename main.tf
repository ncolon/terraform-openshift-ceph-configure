# TODO:
# 1. create pool
# 2. create secret on storage[0]
# 3. copy secret to bastion
# 4. generate kube yaml files
# 5. kubectl create with yaml files


resource "null_resource" "create_openshift_pool" {
  connection {
    type = "ssh"
    host = "${var.storage_private_ip[0]}"
    user = "${var.bastion_ssh_user}"
    password = "${var.bastion_ssh_password}"
    bastion_host = "${var.bastion_ip_address}"
    private_key = "${var.bastion_ssh_private_key}"
  }

  provisioner "file" {
      source = "${path.module}/scripts/createpool.sh"
      destination = "/tmp/createpool.sh"
  }

  provisioner "remote-exec" {
      inline = [
          "sudo chmod +x /tmp/createpool.sh",
          "sudo /tmp/createpool.sh",
      ]
  }
}

resource "null_resource" "bastion_copy_secrets" {
    connection {
      type = "ssh"
      host = "${var.bastion_ip_address}"
      user = "${var.bastion_ssh_user}"
      password = "${var.bastion_ssh_password}"
      bastion_host = "${var.bastion_ip_address}"
      private_key = "${var.bastion_ssh_private_key}"
    }

    provisioner "remote-exec" {
        inline = [
            "scp ${var.storage_private_ip[0]}:/tmp/client.admin.secret.txt /tmp/client.admin.secret.txt",
            "scp ${var.storage_private_ip[0]}:/tmp/client.kube.secret.txt  /tmp/client.kube.secret.txt",
        ]
    }
    depends_on = ["null_resource.create_openshift_pool"]
}


resource "null_resource" "master_copy_secrets" {
    connection {
      type = "ssh"
      host = "${var.bastion_ip_address}"
      user = "${var.bastion_ssh_user}"
      password = "${var.bastion_ssh_password}"
      bastion_host = "${var.bastion_ip_address}"
      private_key = "${var.bastion_ssh_private_key}"
    }

    provisioner "remote-exec" {
        inline = [
            "scp /tmp/client.admin.secret.txt ${var.master_private_ip[0]}:/tmp/client.admin.secret.txt",
            "scp /tmp/client.kube.secret.txt  ${var.master_private_ip[0]}:/tmp/client.kube.secret.txt",
        ]
    }
    depends_on = ["null_resource.bastion_copy_secrets"]
}

locals {
    monitor_string = "${join(":6789,", var.storage_private_ip)}"
}

resource "null_resource" "configure_openshift" {
    connection {
        type = "ssh"
        host = "${var.master_private_ip[0]}"
        user = "${var.bastion_ssh_user}"
        password = "${var.bastion_ssh_password}"
        bastion_host = "${var.bastion_ip_address}"
        private_key = "${var.bastion_ssh_private_key}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/configure_openshift.sh"
        destination = "/tmp/configure_openshift.sh"
    }
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/configure_openshift.sh",
            "/tmp/configure_openshift.sh ${local.monitor_string}",
        ]
    }
    depends_on = ["null_resource.master_copy_secrets"]
}

resource "null_resource" "edit_master_config" {
    count = "${var.master["nodes"]}"
    connection {
        type = "ssh"
        host = "${element(var.master_private_ip, count.index)}"
        user = "${var.bastion_ssh_user}"
        password = "${var.bastion_ssh_password}"
        bastion_host = "${var.bastion_ip_address}"
        private_key = "${var.bastion_ssh_private_key}"
    }

    provisioner "file" {
        source = "${path.module}/scripts/edit_master_config.sh"
        destination = "/tmp/edit_master_config.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod +x /tmp/edit_master_config.sh",
            "sudo /tmp/edit_master_config.sh",
        ]
    }
    depends_on = ["null_resource.configure_openshift"]
}
