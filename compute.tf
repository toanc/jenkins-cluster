
### To Provision FireWall rule ###

resource "google_compute_firewall" "www" {
  name = "tf-www-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8080", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


### To provision Jenkins Master ###

resource "google_compute_instance" "jenkins-master-1" {
   name = "jenkins-master-1"
   machine_type = "f1-micro"
   zone = "us-west1-a"
   tags = ["jenkins"]
   boot_disk {
      initialize_params {
      image = "ubuntu-1604-lts"
   }
}
network_interface {
   network = "default"
   access_config {}
}
service_account {
   scopes = ["userinfo-email", "compute-ro", "storage-ro"]
   }

 metadata_startup_script = <<SCRIPT
apt install -y update
apt install -y docker.io
systemctl enable docker
systemctl start docker
docker pull toanc/jenkins-master:latest
docker run -d -p 8080:8080 -p 50000:50000 --name master-1 toanc/jenkins-master
wget https://raw.githubusercontent.com/eficode/wait-for/master/wait-for -P /tmp
chmod +x /tmp/wait-for
/bin/sh /tmp/wait-for localhost:8080 -t 90
sleep 90
i=`hostname --ip-address`
f=`docker exec -i master-1 bash -c 'java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -remoting groovy /tmp/findkey --username admin --password admin'`

echo $f > /tmp/checkf
curl -X POST https://api.keyvalue.xyz/07580978/visenze --data ' ip: '$i' secret: '$f' '
SCRIPT

 metadata {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
   }
}

output "public_ip_master" {
   value = ["${google_compute_instance.jenkins-master-1.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

### To provision Jenkins Slave ###
resource "google_compute_instance" "jenkins-slave-1" {
   name = "jenkins-slave-1"
   machine_type = "f1-micro"
   zone = "us-west1-a"
   tags = ["jenkins"]
   boot_disk {
      initialize_params {
      image = "ubuntu-1604-lts"
   }
}
network_interface {
   network = "default"
   access_config {}
}
service_account {
   scopes = ["userinfo-email", "compute-ro", "storage-ro"]
   }

 metadata_startup_script = <<SCRIPT
apt install -y update
apt install -y docker.io
systemctl enable docker
systemctl start docker
docker pull jenkinsci/jnlp-slave
sleep 120
wget https://api.keyvalue.xyz/07580978/visenze -P /tmp
cat /tmp/visenze | awk '{ print $2}' > /tmp/ip.address
cat /tmp/visenze | awk '{ print $4}' > /tmp/secret
ipaddress=`cat /tmp/ip.address`
secret=`cat /tmp/secret`
docker run -d --name jenkins-slave1 jenkinsci/jnlp-slave -url http://$ipaddress:8080 $secret slave-1
SCRIPT

metadata {
    sshKeys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
   }
}

output "public_ip_slave" {
   value = ["${google_compute_instance.jenkins-slave-1.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
