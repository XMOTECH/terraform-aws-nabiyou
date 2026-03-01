terraform {
  backend "s3" {
    bucket = "terraform-state-nabiyou-123"
    key    = "nabiyou/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- NOUVEAU : Le Pare-feu (Security Group) ---
resource "aws_security_group" "web_sg" {
  name        = "Serveur-Web-SG"
  description = "Autoriser HTTP et SSH"

  # Règle d'entrée : Autoriser SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Règle d'entrée : Autoriser HTTP (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 signifie "ouvert au monde entier"
  }

  # Règle de sortie : Autoriser le serveur à aller sur internet (pour télécharger Docker etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 signifie "tous les protocoles"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- NOUVEAU : La clé SSH ---
resource "aws_key_pair" "ma_cle_ssh" {
  key_name   = "cle-nabiyou"
  public_key = file("nabiyou_key.pub") # Terraform va lire le fichier qu'on vient de créer
}

# --- MODIFIÉ : Notre serveur ---
resource "aws_instance" "mon_premier_serveur" {
  ami           = data.aws_ami.ubuntu.id 
  instance_type = "t3.micro"             
	
  # On ajoute la clé ici !
  key_name      = aws_key_pair.ma_cle_ssh.key_name
	
  # On attache le pare-feu qu'on vient de créer !
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Serveur-Nabiyou-Cloud"       
  }
}

# --- NOUVEAU : Afficher l'IP publique à la fin ---
output "adresse_ip_publique" {
  value = aws_instance.mon_premier_serveur.public_ip
}
