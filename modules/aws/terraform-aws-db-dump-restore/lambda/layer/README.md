# Crear layer de lambda PostgreSQL para dump restore

### 1. Iniciar un contenedor con una imagen de Amazon Linux 2023

```bash
docker run -it amazonlinux:2023 /bin/bash
```

### 2. Actualizar paquetes e instalar herramientas necesarias

```bash
dnf update -y
dnf install -y gcc make readline-devel zlib-devel openssl-devel wget tar perl flex bison libicu libicu-devel which
```

### 3. Crear directorio de instalación y descargar PostgreSQL

```bash
mkdir -p /usr/local/pgsql17
cd /usr/local/src
wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz # Ultima version de la layer
tar -xzf postgresql-17.0.tar.gz
cd postgresql-17.0
```

### 4. Configurar y compilar PostgreSQL

```bash
./configure --prefix=/usr/local/pgsql17 --with-openssl
make
make install
```
### 5. Crear estructura para la Lambda Layer

```bash
mkdir -p /tmp/pg/bin
mkdir -p /tmp/pg/lib
```

### 6. Verificar dependencias del binario `psql`

```bash
ldd /usr/local/pgsql17/bin/psql # dump restore
```

### 7. Copiar binario y librerías necesarias

```bash
# Verificar con which donde se encuentra el binario de psql
which psql
cp /usr/local/pgsql17/bin/psql /tmp/pg/bin/
# Todas las librerias de aca abajo son las que salieron en el paso 6
cp /usr/local/pgsql17/lib/libpq.so.5 /tmp/pg/lib/
cp /lib64/libreadline.so.8 /tmp/pg/lib/
cp /lib64/libm.so.6 /tmp/pg/lib/
cp /lib64/libc.so.6 /tmp/pg/lib/
cp /lib64/libssl.so.3 /tmp/pg/lib/
cp /lib64/libcrypto.so.3 /tmp/pg/lib/
cp /lib64/libtinfo.so.6 /tmp/pg/lib/
cp /lib64/ld-linux-x86-64.so.2 /tmp/pg/lib/
cp /lib64/libz.so.1 /tmp/pg/lib/
```

### 8. Comprimir en un ZIP

```bash
cd /tmp/pg
zip -r ../pg.zip .
```

### 9. Copiar el ZIP al local

Sin cerrar donde estemos corriendo el contendor, abrir otra terminal y ejecutar:

```bash
docker ps  # Obtener ID del contenedor
docker cp <container_id>:/tmp/pg.zip ./
```

Mover el archivo `pg.zip` a `modules/aws/terraform-aws-db-dump-restore/lambda/layer`

---

# Crear layer de lambda MySQL para dump restore

### 1. Iniciar un contenedor con una imagen de Amazon Linux 2023

```bash
docker run -it amazonlinux:2023 /bin/bash
```

### 2. Actualizar paquetes e instalar herramientas necesarias

```bash
dnf update -y
dnf install -y wget tar gzip libaio which zip
```

### 3. Crear directorio de instalación y descargar MySQL

```bash
mkdir -p /usr/local/mysql
cd /usr/local/src
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
dnf --disablerepo='*' --enablerepo='mysql80-community' list available
dnf install -y mysql-community-client
```

### 4. Crear estructura para la Lambda Layer

En la terminal donde estabamos corriendo el contenedor anterior:

```bash
mkdir -p /tmp/mysql/bin
mkdir -p /tmp/mysql/lib
```

### 5. Verificar dependencias del binario `mysql`

```bash
ldd /usr/bin/mysql # dump restore
```

### 6. Copiar binario y librerías necesarias

```bash
# Verificar con which donde se encuentra el binario de mysql
which mysql
cp /usr/bin/mysql /tmp/mysql/bin/
# Todas las librerias de aca abajo son las que salieron en el paso 5
cp /lib64/libssl.so.3 /tmp/mysqldump/lib/
cp /lib64/libcrypto.so.3 /tmp/mysqldump/lib/
cp /lib64/libresolv.so.2 /tmp/mysqldump/lib/
cp /lib64/libm.so.6 /tmp/mysqldump/lib/
cp /lib64/libncurses.so.6 /tmp/mysqldump/lib/
cp /lib64/libtinfo.so.6 /tmp/mysqldump/lib/
cp /lib64/libstdc++.so.6 /tmp/mysqldump/lib/
cp /lib64/libgcc_s.so.1 /tmp/mysqldump/lib/
cp /lib64/libc.so.6 /tmp/mysqldump/lib/
cp /lib64/libz.so.1 /tmp/mysqldump/lib/
cp /lib64/ld-linux-x86-64.so.2 /tmp/mysqldump/lib/
```

### 7. Comprimir en un ZIP

```bash
cd /tmp/mysql
zip -r ../mysql.zip .
```

### 8. Copiar el ZIP al local

Sin cerrar donde estemos corriendo el contendor, abrir otra terminal y ejecutar:

```bash
docker ps  # Obtener ID del contenedor
docker cp <container_id>:/tmp/mysql.zip ./
```

Mover el archivo `mysql.zip` a `modules/aws/terraform-aws-db-dump-restore/lambda/layer`