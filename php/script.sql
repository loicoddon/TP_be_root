CREATE USER 'beroot_admin'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON * . * TO 'beroot_admin'@'localhost';
flush privileges;