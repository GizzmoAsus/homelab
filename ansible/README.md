# Post Execution Setup Steps

## GPU node steps

Once the GPU nodes have been created, there are 2 things that need to be done:

1. Disable secure boot from the VM
2. Mount the mass storage drive on /var/lib/kubelet
3. Label the nodes

### Disable Secure Boot

The reason secure boot needs to be disabled is that the nvidia operator leverages images and kernerl modules that whilst signed are no recognised by our host VM and therefore prevented from running.

1. Lanch console for the VM
2. Reboot the VM
3. Tap Esc on proxmox screen to enter VM bios
4. Turn off secure boot and continue
5. Ensure VM's boots to login prompt

### Mount Kubelet Drive

1. **Verify the new disk is present**

   ```bash
   lsblk
   # You should see something like:
   # NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
   # sda      8:0    0    50G  0 disk
   # └─sda1   8:1    0    50G  0 part /
   # sdb      8:16   0   300G  0 disk     ← our new, unpartitioned disk
   ```

   If your disk appears under a different name (e.g. `/dev/vdb`), just substitute that path throughout.

2. **Create a single partition (GPT → one primary partition spanning the entire disk)**

   ```bash
   parted /dev/sdb --script mklabel gpt \
       mkpart primary 1MiB 100%
   ```

   After this, you should have `/dev/sdb1`. Confirm with:

   ```bash
   lsblk /dev/sdb
   # e.g.:
   # NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
   # sdb      8:16   0   300G  0 disk
   # └─sdb1   8:17   0   300G  0 part
   ```

3. **Format `/dev/sdb1` as ext4**

   > **If you prefer XFS instead of ext4**, install `xfsprogs` (`apt install xfsprogs`) and use `mkfs.xfs -f /dev/sdb1` in place of the ext4 command below.

   ```bash
   # Install e2fsprogs if not already present (needed for mkfs.ext4)
   apt-get update
   apt-get install -y e2fsprogs

   # Force-format as ext4
   mkfs.ext4 -F /dev/sdb1
   ```

4. **Fetch the UUID of the new partition**

   ```bash
   UUID=$(blkid -s UUID -o value /dev/sdb1)
   echo "Detected UUID = $UUID"
   ```

5. **Create the target mount point and adjust permissions**

   ```bash
   mkdir -p /var/lib/kubelet
   chown root:root /var/lib/kubelet
   chmod 0755 /var/lib/kubelet
   ```

6. **Add an `/etc/fstab` entry so it remounts on reboot**
   Append a line like this (assuming ext4):

   ```bash
   cat <<EOF >> /etc/fstab
   UUID=${UUID}   /var/lib/kubelet   ext4   defaults   0 2
   EOF
   ```

   > If you used XFS, change `ext4` → `xfs` in the fstab line.

7. **Mount it immediately**

   ```bash
   mount /var/lib/kubelet
   ```

   Confirm with:

   ```bash
   df -h /var/lib/kubelet
   # Should show /var/lib/kubelet mounted on /dev/sdb1 with ~300G available.
   ```

8. **Verify everything**

   ```bash
   grep /var/lib/kubelet /etc/fstab
   # e.g.:
   # UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /var/lib/kubelet   ext4   defaults   0 2

   mount | grep /var/lib/kubelet
   # e.g.:
   # /dev/sdb1 on /var/lib/kubelet type ext4 (rw,relatime,data=ordered)
   ```

## Generic Steps

### Label the nodes

```
kubectl label node k8s-cpu-worker01 node-role.kubernetes.io/worker=cpu
kubectl label node k8s-cpu-worker02 node-role.kubernetes.io/worker=cpu
kubectl label node k8s-cpu-worker03 node-role.kubernetes.io/worker=cpu
kubectl label node k8s-gpu-worker04 node-role.kubernetes.io/worker=gpu
kubectl label node k8s-gpu-worker05 node-role.kubernetes.io/worker=gpu
```
