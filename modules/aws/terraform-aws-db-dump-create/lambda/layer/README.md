# Crear layer de lambda PostgreSQL para dump create 

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

### 5. Verificar dependencias del binario `pg_dump`

```bash
ldd /usr/local/pgsql17/bin/psql # dump restore
```

### 6. Crear estructura de carpetas

```bash
mkdir -p /tmp/pgdump/bin
mkdir -p /tmp/pgdump/lib
```

### 7. Copiar binario y librerías necesarias

```bash
# Verificar con which donde se encuentra el binario de pg_dump
which pg_dump
cp /usr/local/pgsql17/bin/pg_dump /tmp/pgdump/bin/
# Todas las librerias de aca abajo son las que salieron en el paso 5
cp /usr/local/pgsql17/lib/libpq.so.5 /tmp/pgdump/lib/
cp /lib64/libssl.so.3 /tmp/pgdump/lib/
cp /lib64/libcrypto.so.3 /tmp/pgdump/lib/
cp /lib64/libz.so.1 /tmp/pgdump/lib/
```

### 8. Comprimir en un ZIP

```bash
cd /tmp/pgdump
zip -r ../pgdump.zip .
```
### 9. Copiar el ZIP al local

Sin cerrar donde estemos corriendo el contendor, abrir otra terminal y ejecutar:

```bash
docker ps  # Obtener ID del contenedor
docker cp <container_id>:/tmp/pgdump.zip ./
```

Mover el archivo `pgdump.zip` a `modules/aws/terraform-aws-db-dump-create/lambda/layer`

---

# Crear layer de lambda MySQL para dump create 

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

### 4. Verificar dependencias del binario `mysql_dump`

```bash
ldd /usr/bin/mysqldump # dump create
```

### 5. Crear estructura de carpetas

```bash
mkdir -p /tmp/mysqldump/bin
mkdir -p /tmp/mysqldump/lib
```

### 6. Copiar binario y librerías necesarias

```bash
# Verificar con which donde se encuentra el binario de mysqldump
which mysqldump
cp /usr/bin/mysqldump /tmp/mysqldump/bin/
# Todas las librerias de aca abajo son las que salieron en el paso 4
cp /lib64/libssl.so.3 /tmp/mysqldump/lib/
cp /lib64/libcrypto.so.3 /tmp/mysqldump/lib/
cp /lib64/libresolv.so.2 /tmp/mysqldump/lib/
cp /lib64/libm.so.6 /tmp/mysqldump/lib/
cp /lib64/libstdc++.so.6 /tmp/mysqldump/lib/
cp /lib64/libgcc_s.so.1 /tmp/mysqldump/lib/
cp /lib64/libc.so.6 /tmp/mysqldump/lib/
cp /lib64/libz.so.1 /tmp/mysqldump/lib/
cp /lib64/ld-linux-x86-64.so.2 /tmp/mysqldump/lib/
```

### 7. Comprimir en un ZIP

```bash
cd /tmp/mysqldump
zip -r ../mysqldump.zip .
```
### 8. Copiar el ZIP al local

Sin cerrar donde estemos corriendo el contendor, abrir otra terminal y ejecutar:

```bash
docker ps  # Obtener ID del contenedor
docker cp <container_id>:/tmp/mysqldump.zip ./
```

Mover el archivo `mysqldump.zip` a `modules/aws/terraform-aws-db-dump-create/lambda/layer`