if [ -f "/disk_uuid" ]; then
  uuid=$(cat /disk_uuid)
  disk=$(blkid -U $uuid)
  if [ ! -z "$disk" ]; then
    echo $disk
    exit 0
  fi
fi

if [ -f "/disk_dev" ]; then
  cat /disk_dev
  exit 0
fi

echo $(list-devices disk | head -n1)