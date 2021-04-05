variable "db" {
  type = object({
    master_name = string
    password = string
    })
  description = "used to configure docdb's username and password"
}