output "address" {
  value       = module.data_stores.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.data_stores.port
  description = "The port the database is listening on"
}
