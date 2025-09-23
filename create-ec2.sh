#!/bin/bash

# ==== Налаштування (замінити на свої дані) ====
AMI_ID="ami-01bc990364452ab3e"
INSTANCE_TYPE="t3.micro"
KEY_NAME=""
SECURITY_GROUP_ID="sg-"
SUBNET_ID="subnet-"
INSTANCE_NAME="Test-Apache-VM"

# ==== Створюємо user-data файл ====
cat > user-data.sh <<'EOF'
#!/bin/bash
yum update -y
yum install -y mc git vim httpd
systemctl enable httpd
systemctl start httpd

# Тестова сторінка
echo "<h1>Hello from AWS EC2!</h1>" > /var/www/html/index.html
EOF

# ==== Запуск EC2 ====
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "EC2 instance запущено: $INSTANCE_ID"
echo "Очікуємо публічну IP-адресу..."

# ==== Очікуємо і дістаємо публічний IP ====
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "Готово! Підключення по SSH:"
echo "ssh -i $KEY_NAME.pem ec2-user@$PUBLIC_IP"

echo "Відкрий у браузері: http://$PUBLIC_IP"
