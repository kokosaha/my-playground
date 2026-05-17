#!/bin/bash
set -e

cd "$(dirname "$0")"

# 创建数据库
docker exec mysql57 mysql -uroot -proot123 -e "CREATE DATABASE IF NOT EXISTS \`usergf_uapdb_dev\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
docker exec mysql57 mysql -uroot -proot123 -e "CREATE DATABASE IF NOT EXISTS \`usergf_hmsvcdb_dev\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# 导入数据
docker exec -i mysql57 mysql -uroot -proot123 usergf_uapdb_dev < usergf_uapdb_dev.sql
docker exec -i mysql57 mysql -uroot -proot123 usergf_hmsvcdb_dev < usergf_hmsvcdb_dev.sql

echo "Import complete!"
docker exec mysql57 mysql -uroot -proot123 -e "SHOW DATABASES;"
