output "outputs" {
  value = {
    DBEndpoint      = google_sql_database_instance.main.private_ip_address
    DBPort          = "5432"
    DBUser          = google_sql_user.main.name
    DBName          = local.db_name
    connection_name = google_sql_database_instance.main.connection_name
    instance_name   = google_sql_database_instance.main.name
  }
}
