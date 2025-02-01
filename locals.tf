locals {
   ssh_key = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
}