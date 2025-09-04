# ---------------------------------------------------------------------------------------------------------------------
# EFS FOR PERSISTENT STORAGE
# Replaces Docker volumes from docker-compose
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_efs_file_system" "n8n_storage" {
  creation_token = "${var.cluster_name}-n8n-storage"
  encrypted      = true

  tags = {
    Name = "${var.cluster_name}-n8n-storage"
  }
}

resource "aws_efs_access_point" "n8n_data" {
  file_system_id = aws_efs_file_system.n8n_storage.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/n8n-data"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 755
    }
  }

  tags = {
    Name = "${var.cluster_name}-n8n-access-point"
  }
}

resource "aws_efs_mount_target" "n8n_storage" {
  count          = length(var.private_subnet_ids)
  file_system_id = aws_efs_file_system.n8n_storage.id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}