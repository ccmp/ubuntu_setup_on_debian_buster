# Ubuntu Install
 * ** 編集中 **

## Crate Image
## Ubuntu Install

## Ubuntu Installの手順(SATA)

 * このgitのレポジトリを取得

```
# git clone https://github.com/ccmp/ubuntu_setup_on_debian_buster.git
```

 * ubuntu_install.shはnvme用になっているのでSATAの場合は編集が必要。
   * ここでは /dev/sda1にrootfsをインストールするものとする。
     * nvme0n1 -> sda
	 * nvme0n1p1 -> sda1

 * ubuntu_install.shを編集

```
::w !diff % -
4c4
< dev=/dev/nvme0n1
---
> dev=/dev/sda
39,40c39,40
< mkfs.fat -F32 -n efi ${dev}p2
< mkfs.ext4 -F -L ubuntu ${dev}p1
---
> mkfs.fat -F32 -n efi ${dev}2
> mkfs.ext4 -F -L ubuntu ${dev}1
42c42
< fatlabel ${dev}p2 ESP
---
> fatlabel ${dev}2 ESP
75c75
< linux /boot/vmlinuz root=${dev}p1 vga=0x305 panic=10
---
> linux /boot/vmlinuz root=${dev}1 vga=0x305 panic=10
79c79
< linux /boot/vmlinuz.old root=${dev}p1 vga=0x305 panic=10
---
> linux /boot/vmlinuz.old root=${dev}1 vga=0x305 panic=10
95c95
< ${dev}p1  /               ext4    errors=remount-ro 0       1
---
> ${dev}1  /               ext4    errors=remount-ro 0       1
shell returned 1
```

 * インストール
   * ```desktop```を指定してunbuntu_install.shを実行
   * イメージはyodaにあるアーカイブを取得してくる。
   
```
root@100:~/ubuntu_setup_on_debian_buster# ./ubuntu_install.sh desktop
```

 * スクリプトは途中でエラーになっても進行するので上手くいかなかった場合遡って確認すること。
 * 問題なく実行されると、最後にgrubの設定をして終了する。
```
...
...
Installation finished. No error reported.
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.4.0-88-generic
Found initrd image: /boot/initrd.img-5.4.0-88-generic
Found linux image: /boot/vmlinuz-5.4.0-26-generic
Found initrd image: /boot/initrd.img-5.4.0-26-generic
done
root@100:~/ubuntu_setup_on_debian_buster#
```
