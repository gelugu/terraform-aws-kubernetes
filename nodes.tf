resource "aws_key_pair" "main" {
  public_key = var.ssh_public_key
  key_name   = "${var.cluster_name}-nodes-ssh-key"
}

resource "aws_instance" "master" {
  ami           = var.instance_ami
  instance_type = var.master_instance_type

  count = var.master_count

  key_name = aws_key_pair.main.key_name

  user_data                   = count.index > 0 ? file("${path.module}/init-controller.sh") : file("${path.module}/init-controller-main.sh")
  user_data_replace_on_change = true
  associate_public_ip_address = true

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.all.id]

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    KubernetesCluster = var.cluster_name
    Name              = "${var.cluster_name}_k8s_controller_${count.index}"
  }
}

resource "aws_instance" "worker" {
  ami           = var.instance_ami
  instance_type = var.master_instance_type

  count = var.worker_count

  key_name = aws_key_pair.main.key_name

  user_data = file("${path.module}/init-worker.sh")
  user_data_replace_on_change = true
  associate_public_ip_address = true

  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.all.id]

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name              = "${var.cluster_name}_k8s_worker_${count.index}"
    KubernetesCluster = var.cluster_name
  }

  depends_on = [aws_instance.master]
}

output "join_command" {
  value = "ssh ubuntu@${aws_instance.master[0].public_ip} -i ~/.ssh/aws-gelugu 'sudo kubeadm token create --print-join-command'"
}
