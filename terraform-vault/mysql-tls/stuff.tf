resource "vault_mount" "db" {
  path = "mysql"
  type = "database"
}

resource "vault_database_secret_backend_connection" "test" {
  backend = "${vault_mount.db.path}"
  name = "testdb"
  allowed_roles = ["dev", "prod"]
  root_rotation_statements = ["FOOBAR"]

  verify_connection=true

  mysql {
    connection_url = "{{username}}:{{password}}@tcp(127.0.0.1:3306)/"
    tls_certificate_key = file("certs/combined.pem")
    tls_ca = file("certs/hashicorp-ca.pem")
    max_open_connections = 4
  }

  data = {
    username = "root"
    password = "yoursql"
  }
}
