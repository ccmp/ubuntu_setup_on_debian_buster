# Ubuntu Install

## git レポジトリ取得

 * Ubuntuをインストールする対象サーバ上でgitのレポジトリを取得
 
```
# git clone https://github.com/ccmp/ubuntu_setup_on_debian_buster.git
```

## Create Image(省略可能)
 * イメージは```ubuntu_install.sh```実行時にネットワーク経由で```yoda```から取得されるため、基本作成する必要はない。
   * Create Imageで作成されたイメージがローカルにある場合はローカルが優先される。
 * 準備
 ```
 # ./prep.sh
 ```
 * イメージ作成
 ```
 Usage: crateimg.sh "[server|desktop]";
 ```
   * ./Build以下にイメージが作成される。
   * ex. desktop用のイメージを作成する場合。
   ```
   # ./createimg.sh desktop
   ```

## Ubuntu Install
 * インストールを実行
   * nvmeの場合```/dev/nvmen1```,sataの場合```/dev/sda```として対象ドライブが認識されていることが前提
   ```
   Usage: ubuntu_install.sh [server|desktop] [sata|(nvme)]
   ```
   * ex. desktopをsataにインストールする場合
   ```
   # ./ubuntu_install.sh desktop sata
   ```

 * インストールスクリプトは途中でエラーになっても進行するので上手くいかなかった場合遡って確認すること。
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
