output "module_completed" {
    value = "${null_resource.edit_master_config.*.id}"
}
